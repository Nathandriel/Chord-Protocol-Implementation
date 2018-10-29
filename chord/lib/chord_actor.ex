defmodule ChordActor do
    
    use GenServer
    @time_interval 1
    @m 160
    ##########################################################################
    #State: {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}
    ##########################################################################

    # Client Side
    def start_link(default) do
      GenServer.start_link(__MODULE__, default)
    end

    def get_hash(pid) do
        st = :erlang.pid_to_list(pid)
        {hash,_} = :crypto.hash(:sha,st) |> Base.encode16(case: :lower) |> Integer.parse(16)
        hash
    end

    def set_initial_state(first, second) do
        GenServer.call(first, {:set_initial_state, second})
        GenServer.call(second, {:set_initial_state, first})
    end

    def init_fingers(pid) do
        GenServer.call(pid, :init_fingers)
    end
  
    def find_successor(existing, id, originated_from)do

        res = GenServer.call(existing,{:find_successor, id, originated_from},15000)

        successor = case res do 
            nil ->  closest_prec_node = find_closest_preceeding_node(existing, id)
                    if (existing == closest_prec_node) do
                        existing    #newly joined node's successor is existing node
                    else
                        find_successor(closest_prec_node, id, originated_from)
                    end
                        
            _   ->  res
        end

      successor
    end

    def my_find_successor(id, myHash, successor, hashList, successorList, originated_from) do
        res = if (id > myHash && id <= get_hash(successor)) do
                successor
            end
        
        suc = case res do 
        nil ->  node = recurse(id, myHash, hashList, successorList,@m)
                closest_prec_node = if !node, do: self(), else: node

                if (closest_prec_node == self()) do
                    #IO.inspect "Found in finger table"
                    self()
                else 
                    #IO.inspect "#########################"
                    find_successor(closest_prec_node, id, originated_from)
                end
                    
        _   ->  res
        end

    
        suc
        

    end

    def get_predecessor(pid) do
        pred = GenServer.call(pid,:get_predecessor,15000)
    end

    def find_closest_preceeding_node(pid, id) do
        closest_prec_node = GenServer.call(pid, {:find_closest_preceeding_node, id},15000)
    end


    def set_hash(pid) do
      GenServer.cast(pid,:set_hash)
    end


    # stabilize
    def stabilize(pid) do
        Process.send_after(pid,:stabilize,@time_interval)
    end

    # fix fingers
    def fix_fingers(pid) do
        Process.send_after(pid, :fix_fingers, @time_interval)
    end

    def search_keys_periodically(pid) do
        Process.send_after(pid, :search_keys, @time_interval)
    end
    
    # check predecessor
    def check_predecessor() do
        Process.send_after(self(),:check_predecessor, @time_interval)
    end

    #notify
    def notify(sendTo,sendThis) do
        GenServer.cast(sendTo,{:notify,sendThis})
    end

    #create
    def create(pid) do
        GenServer.call(pid,:create)
    end
    
    #join
    def join(existing, new) do
        GenServer.call(new,{:join,existing})
    end

    # Server Side (callbacks)
    def init(default) do
      {:ok, default}
    end



    #################### Handle_Info #####################

    def handle_info(:fix_fingers, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        #IO.inspect "Index value #{fingerNext}"
        index = if (fingerNext > ((@m) -1) )do
                0
            else
                fingerNext
            end

        id = (myHash + :math.pow(2, index-1)) |> round
        base = Kernel.trunc(:math.pow(2, @m))
        id_mod = rem(id, base)

        suc = my_find_successor(id_mod, myHash, successor, hashList, successorList, :from_fix_fingers)
        suc_hash = get_hash(suc)
                
        updated_suc_list = List.update_at(successorList, index, fn(_) -> suc end )
        updated_hash_list = List.update_at(hashList, index, fn(_) -> suc_hash end)

        fix_fingers(self())

        #IO.inspect updated_suc_list

        { :noreply, {main_pid,predecessor,successor,myHash,index+1,numHops,numRequests,updated_hash_list, updated_suc_list} }
    end


    def handle_info(:stabilize, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do

        #To avoid calling the same process from itself
        updated_state = if (self() == successor) do
            #IO.puts "In stabilize: successor is self"
            {:noreply, {main_pid,self(),self(),myHash,fingerNext,numHops,numRequests,hashList, successorList}}
        else
            #IO.puts "In stabilize: suc is not self"
            x = get_predecessor(successor)
            
            xHash = if x != nil do 
                        get_hash(x)
                    else 
                        -1
                    end
            # IO.inspect x
            # IO.inspect "value of xHash is #{xHash}"
             
            if (xHash > myHash && xHash < get_hash(successor)) do
                # Notify the new successor that Hey! I've become your predecessor
                notify(x,self())
                { :noreply, {main_pid,predecessor,x,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
            else
                # If our seccessor is still the same hence, nothing will happen in the call
                notify(successor, self())
                { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
            end
        end

        
        Process.send_after(self(),:stabilize, @time_interval)
        
        updated_state
        
    end
    
    

    def handle_info(:check_predecessor, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        
        # Process.send_after(self(),:check_predecessor, @time_interval)
        # { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,hashList, successorList} }
        
    end

    def handle_info(:search_keys, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        #IO.inspect "SEARCHING KEYS**********************"
        if (numRequests == 1) do
            GenServer.cast(main_pid, {:done, numHops+1})
        else
            #IO.inspect "MOre requests to make"
            rand_key_hash = Enum.random(1..round(:math.pow(2,@m)-1))
            my_find_successor(rand_key_hash, myHash, successor, hashList, successorList, :from_search)
            search_keys_periodically(self())
        end
        #decrement numRequests by 1 after every search is made
        {:noreply, {main_pid,predecessor,successor,myHash,fingerNext,numHops+1,numRequests-1,hashList, successorList} }
    end


    #################### Handle_Call #####################
    # create
    def handle_call(:create, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        successor = self()
        hash = get_hash(self())
        
        #set values of successor and myHash
        {:reply,hash,{main_pid,nil,successor,hash,fingerNext,numHops,numRequests,hashList, successorList}}
    end

    def handle_call({:set_initial_state, other}, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        suc = if (get_hash(other) > myHash) do
                    other
                else
                    self()
                end

        prec = if (get_hash(other) < myHash) do
                    other
            else
                nil
            end

        {:reply,:foo,{main_pid,prec,suc,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end


    # join
    def handle_call({:join,existing},  _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        x = find_successor(existing, myHash,:from_join)
               
        {:reply,:joined,{main_pid,nil,x,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end


    #get a pid's predecessor
    def handle_call(:get_predecessor, _from, {main_pid, predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        
        
        {:reply,predecessor,{main_pid, predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end

    # find successor
    def handle_call({:find_successor, id, originated_from}, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} ) do
        
        res = if (id > myHash && id <= get_hash(successor)) do
                successor
            end
        #IO.inspect "Incoming call from  #{originated_from} "
        if originated_from == :from_search do 
        #IO.inspect "entered find suc from_search"  
        {:reply, res, {main_pid,predecessor,successor,myHash,fingerNext,numHops+1,numRequests,hashList, successorList} }
        else
        {:reply, res, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
        end
    end

    def recurse(id, myHash, hashList,successorList,i) when i==0 do
        nil
    end

    def recurse(id, myHash, hashList,successorList,i) do
        if (Enum.at(hashList, i) > myHash and Enum.at(hashList, i) < id) do
             Enum.at(successorList, i)
        
        else
            recurse(id, myHash, hashList,successorList,i-1)
        end
    end
    

    # find closest preceeding node
    def handle_call({:find_closest_preceeding_node, id}, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        
        node = recurse(id, myHash, hashList,successorList,@m)
        
        cl_prec_node = if !node, do: self(), else: node

        {:reply, cl_prec_node, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }

    end

    def handle_call(:init_fingers, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        hashList = for _ <- @m..1 do
                    myHash
                end
        successorList = for _ <- @m..1 do
                    successor
                end

        
        {:reply, hashList, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }

    end
     

    #################### Handle_Casts #####################
    def handle_cast(:set_hash, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do 
      hash = get_hash(self())
      {:noreply, {main_pid,predecessor,successor,hash,fingerNext,numRequests,hashList, successorList}}  
    end

    def handle_cast({:notify,newPredecessor}, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do 
        new_pred_hash = get_hash(newPredecessor)
        pred_hash = if predecessor != nil do
                        get_hash(predecessor)
                    else
                        -1
                    end

        if (predecessor == nil || (new_pred_hash > pred_hash && new_pred_hash < myHash) ) do
            {:noreply, {main_pid,newPredecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
        else
            {:noreply, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
        end
    end


end