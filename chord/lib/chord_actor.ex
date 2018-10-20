defmodule ChordActor do
    
    use GenServer
    @time_interval 1
    @m 256
    ##########################################################################
    #State: {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}
    ##########################################################################

    # Client Side
    def start_link(default) do
      GenServer.start_link(__MODULE__, default)
    end
  
    def find_successor(pid, id)do
      {successorPid, successorHash} = GenServer.call(pid, {:find_successor, id})
      successorPid
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

    def get_hash(pid) do
        {status,hash} = GenServer.call(pid,:get_hash)
        hash
    end

    # stabilize
    def stabilize_and_fix_fingers(pid) do
       
        Process.send_after(pid,:stabalize,@time_interval)
        #Process.send_after(pid,:check_predecessor,@time_interval)
        Process.send_after(pid,:fix_fingers,@time_interval)
    end

    # fix fingers
    def fix_fingers() do
        Process.send_after(self,:fix_fingers, @time_interval)
    end

    def search_keys_periodically(pid) do
        Process.send_after(pid,:stabalize,@time_interval)
        #Process.send_after(pid,:check_predecessor,@time_interval)
        Process.send_after(pid,:fix_fingers,@time_interval)
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

    #join
    def join(joinMe, joinTo) do
        {} = GenServer.call(joinMe,{:join,joinTo})
    end

    # Server Side (callbacks)
    def init(default) do
      {:ok, default}
    end



    #################### Handle_Info #####################
    def handle_info(:stabilize, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        
        x = get_predecessor(successor)
        xHash = get_hash(x)
        updatedState = 
        if (xHash > myHash && xHash < successor.get_hash()) do
            # Notify the new successor that Hey! I've become your predecessor
            notify(x,self())
            { :noreply, {main_pid,predecessor,x,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
        else
             # If our seccessor is still the same hence, nothing will happen in the call
            notify(successor,self())
            { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }
        end
        Process.send_after(self,:stabilize, @time_interval)
        updatedState
        
    end
    
    def handle_info(:fix_fingers, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        index = nil
        if (fingerNext > ((@m) -1) )do
            index = 0
        else
            index = fingerNext
        end

        id = (myHash + :math.pow(2, index-1)) |> round
        id_mod = rem(id, :math.pow(2, @m))
        
        List.update_at(successorList, index, find_successor(self(), id_mod) )
        List.update_at(hashList, index, fn(x) -> id_mod end)
        
        fix_fingers()
        { :noreply, {main_pid,predecessor,successor,myHash,index+1,numHops,numRequests,hashList, successorList} }
    end

    def handle_info(:check_predecessor, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        
        # Process.send_after(self(),:check_predecessor, @time_interval)
        # { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,hashList, successorList} }
        
    end

    def handle_info(:search_keys, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        rand_key_hash = Enum.random(1..:math.pow(2,@m)-1)
        find_successor(self, rand_key_hash)
        search_keys_periodically(self())
    end


    #################### Handle_Call #####################
    # create
    def handle_call(:create, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        hash = get_hash(self())
        #set successor and myHash to hash
        {:noreply,{main_pid,nil,hash,hash,fingerNext,numHops,numRequests,hashList, successorList}}
    end


    # join
    def handle_call({:join,joinTo},  _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        x = find_successor(joinTo, myHash)
        {:noreply,{main_pid,nil,x,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end

    # get a pid's hash
    def handle_cast(:get_hash, _from, {predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        {:reply,myHash,{predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end

    #get a pid's predecessor
    def handle_cast(:get_predecessor, _from, {predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        {:reply,predecessor,{predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end

    # find successor
    def handle_call({:find_successor, id},  _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} ) do
        res = if (id > myHash && id <= get_hash(successor)) do
            {successor, myHash}
        else
            cl_prec_node = find_closest_preceeding_node(self(), id)
            {successor, myHash} = find_successor(cl_prec_node, id)
        end

        {:reply, res, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }

    end

    

    # find closest preceeding node
    def handle_call({:find_closest_preceeding_node, id}, _from, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        node = nil
        for i <- @m..1 do
            #TODO f finger table entry 
            if (Enum.at(hashList, i) > myHash && Enum.at(hashList, i) < id) do
                #{:reply, Enum.at(successorList, m) , {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }}
                node = Enum.at(successorList, i)
            end
        end
        cl_prec_node = if !node, do: self, else: node
        {:reply, cl_prec_node, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList} }

    end

    #################### Handle_Casts #####################
    def handle_cast(:set_hash, {main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
      hash = :crypto.hash(:sha256,self()) |> Base.encode16(case: :lower) |> Integer.parse()
      {:noreply, {main_pid,predecessor,successor,hash,fingerNext,numRequests,hashList, successorList}}  
    end

    def notify({:notify,newPredecessor},{main_pid,predecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}) do
        {:noreply, {main_pid,newPredecessor,successor,myHash,fingerNext,numHops,numRequests,hashList, successorList}}
    end


end