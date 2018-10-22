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
  
    def find_successor(pid, id)do
    
      {:ok, res} = GenServer.call(pid,{:find_successor, id})
      IO.inspect "suc in find_suc"
      

    successor = case res do 
        nil ->  IO.puts "Looking for closest prec node"
                closest_prec_node = find_closest_preceeding_node(pid, id)
                find_successor(closest_prec_node, id)
                    
        _   ->  res
        end

      
      IO.inspect "client"
      IO.inspect successor
      successor
    end

    def get_predecessor(pid) do
        {status, pred} = GenServer.call(pid,:get_predecessor)
        pred
    end

    def find_closest_preceeding_node(pid, id) do
        closest_prec_node = GenServer.call(pid, {:find_closest_preceeding_node, id})
    end


    def set_hash(pid) do
      GenServer.cast(pid,:set_hash)
    end


    # stabilize
    def stabilize(pid) do
        
        Process.send_after(pid,:stabilize,@time_interval)
        #Process.send_after(pid,:check_predecessor,@time_interval)
        
    end

    # fix fingers
    def fix_fingers(pid) do
        Process.send_after(pid, :fix_fingers, @time_interval)
    end

    def search_keys_periodically(pid) do
        #Process.send_after(pid,:stabilize,@time_interval)
        #Process.send_after(pid,:check_predecessor,@time_interval)
        #Process.send_after(pid,:fix_fingers,@time_interval)
        
        Process.send_after(pid, :search_keys, @time_interval)
    end
    
    # check predecessor
    def check_predecessor() do
        Process.send_after(self,:check_predecessor, @time_interval)
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
        #IO.puts "Enter fix fingers"
        index =
        if (fingerNext > ((@m) -1) )do
            0
        else
            fingerNext
        end

        id = (myHash + :math.pow(2, index-1)) |> round
        base = Kernel.trunc(:math.pow(2, @m))
        id_mod = rem(id, base)
        
        #TODO Figure out a way to update finger table without having to call the same process from itself

        
        List.update_at(successorList, index, fn(x) -> my_find_successor(id_mod, myHash, successor, hashList, successorList) end )
        List.update_at(hashList, index, fn(x) -> id_mod end)

        #IO.puts "updated lists"
        
        fix_fingers(self())
        { :noreply, {main_pid,predecessor,successor,myHash,index+1,numHops,numRequests,hashList, successorList} }
    end

    def my_find_successor(id, myHash, successor, hashList, successorList) do
        IO.puts "call my find"
        res = if (id > myHash && id <= get_hash(successor)) do
                successor
            end
        
        suc = case res do 
        nil ->  #Looking for closest prec node
                
                node = recurse(id, myHash, hashList, successorList,@m)
                closest_prec_node = if !node, do: self, else: node

                if (closest_prec_node == self()) do
                    self()
                else 
                    find_successor(closest_prec_node, id)
                end
                    
        _   ->  res
        end

        IO.puts "my_find_suc"
        IO.inspect suc
        suc
        

    end


    def handle_info(:stabilize, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        #IO.puts "Enter stabilize"

        #To avoid calling the same process from itself
        updated_state = if (self() == successor) do
            {:noreply, {main_pid,self(),self(),myHash,fingerNext,numHops,numRequests,hashList, successorList}}
        else
            x = get_predecessor(successor)
            IO.puts x
            xHash = get_hash(x)
            updatedState = 
            if (xHash > myHash && xHash < get_hash(successor)) do
                # Notify the new successor that Hey! I've become your predecessor
                notify(x,self())
                { :noreply, {main_pid,predecessor,x,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
            else
                # If our seccessor is still the same hence, nothing will happen in the call
                #notify(successor,self())
                { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
            end
        end

        Process.send_after(self,:stabilize, @time_interval)
        updated_state
        
    end
    
    

    def handle_info(:check_predecessor, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        
        # Process.send_after(self(),:check_predecessor, @time_interval)
        # { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,hashList, successorList} }
        
    end

    def handle_info(:search_keys, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        rand_key_hash = Enum.random(1..:math.pow(2,@m)-1)
        find_successor(self(), rand_key_hash)
        search_keys_periodically(self())
    end


    #################### Handle_Call #####################
    # create
    def handle_call(:create, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        #IO.puts "Enter create"
        successor = self()
        hash = get_hash(self())

        #List.update_at(successorList, 0, fn(xself() )
        #List.update_at(hashList, 0, hash)

        successorList = [self()] ++ successorList
        hashList = [hash] ++ hashList

        IO.inspect "suc list"
        IO.inspect successorList

        IO.inspect "hash list"
        IO.inspect hashList
        
        #set successor and myHash to hash
        {:reply,hash,{main_pid,nil,successor,hash,fingerNext,numHops,numRequests,hashList, successorList}}
    end


    # join
    def handle_call({:join,existing},  _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        #IO.puts "Enter join"

        IO.inspect "new node :"
        IO.inspect self()
        IO.inspect "joining to :"
        IO.inspect existing

        x = find_successor(existing, myHash)
        IO.inspect "res of find_suc"
        IO.inspect x
        {:reply,{main_pid,nil,x,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end


    #get a pid's predecessor
    def handle_call(:get_predecessor, _from, {predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        IO.puts "reply from get_pred"
        IO.inspect predecessor
        {:reply,predecessor,{predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end

    # find successor
    def handle_call({:find_successor, id}, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} ) do
        IO.puts "enter suc"

        # IO.inspect self()
        # IO.inspect successor
        
        res = if (id > myHash && id <= get_hash(successor)) do
                successor
            end
            

        IO.inspect res
        
           
    {:reply, res, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
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
        # for i <- @m..1 do
        #     #TODO f finger table entry 
        #     if (Enum.at(hashList, i) > myHash && Enum.at(hashList, i) < id) do
        #         #{:reply, Enum.at(successorList, m) , {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }}
        #         node = Enum.at(successorList, i)
        #     end
        # end

        
        cl_prec_node = if !node, do: self, else: node
        IO.puts "clo prec node"
        IO.inspect cl_prec_node
        {:reply, cl_prec_node, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }

    end

    #################### Handle_Casts #####################
    def handle_cast(:set_hash, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do 
      hash = get_hash(self())
      {:noreply, {main_pid,predecessor,successor,hash,fingerNext,numRequests,hashList, successorList}}  
    end

    def handle_cast({:notify,newPredecessor}, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do 
        {:noreply, {main_pid,newPredecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end


end