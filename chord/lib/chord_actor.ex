defmodule ChordActor do
    
    use GenServer
    @time_interval 1
    ##########################################################################
    #State: {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}
    ##########################################################################

    # Client Side
    def start_link(default) do
      GenServer.start_link(__MODULE__, default)
    end
  
    def find_successor(pid, id)do
      {successorPid, successorHash} = GenServer.call(pid, {:find_successor, id})
    end

    def get_predecessor(pid) do
        {status, pred} = GenServer.call(pid,:get_predecessor)
        pred
    end

    def get_closest_preceeding_node(pid, id) do
        closest_prec_node = GenServer.call(pid, {:closest_preceeding_node, id})
    end

    def set_hash() do
      GenServer.cast(:set_hash)
    end

    def get_hash(pid) do
     {status,hash} = GenServer.call(pid,:get_hash)
     hash
    end

    # stabilize
    def stabilize() do
        Process.send_after(self,:stabilize, @time_interval)
    end

    # fix fingers
    def fix_fingers() do
        Process.send_after(self,:fix_fingers, @time_interval)
    end
    
    # check predecessor
    def check_predecessor() do
        Process.send_after(self,:check_predecessor, @time_interval)
    end

    # find key
    def find(keyHash,pid) do
      
    end

    #notify
    def notify(sendTo,sendThis) do
        GenServer.cast(sendTo,{:notify,sendThis})
    end

    #join
    def join(joinMeWith) do
        GenServer.call(joinMeWith,:join)
    end

    # Server Side (callbacks)
    def init(default) do
      {:ok, default}
    end



    #################### Handle_Info #####################
    def handle_info(:stabilize, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        
        x = get_predecessor(successor)
        xHash = get_hash(x)
        updatedState = 
        if (xHash > myHash && xHash < successor.get_hash()) do
            # Notify the new successor that Hey! I've become your predecessor
            notify(x,self())
            { :noreply, {main_pid,predecessor,x,myHash,fingerNext,numRequests,fingerTable} }
        else
             # If our seccessor is still the same hence, nothing will happen in the call
            notify(successor,self())
            { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} }
        end
        Process.send_after(self,:stabilize, @time_interval)
        updatedState
        
    end
    
    def handle_info(:fix_fingers, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        
        Process.send_after(self(),:fix_fingers, @time_interval)

        { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} }
    end

    def handle_info(:check_predecessor, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        
        # Process.send_after(self(),:check_predecessor, @time_interval)
        # { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} }
        
    end


    #################### Handle_Call #####################
    # create
    def handle_call(:create, _from, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        hash = get_hash(self())
        #set successor and myHash to hash
        {:noreply,{main_pid,nil,hash,hash,fingerNext,numRequests,fingerTable}}
    end


    # join
    def handle_call({:join,joinWith},  _from, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        x = find_successor(joinWith, myHash)
        {:noreply,{main_pid,nil,x,myHash,fingerNext,numRequests,fingerTable}}
    end

    # get a pid's hash
    def handle_cast(:get_hash, _from, {predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        {:reply,myHash,{predecessor,successor,myHash,fingerNext,numRequests,fingerTable}}
    end

    #get a pid's predecessor
    def handle_cast(:get_predecessor, _from, {predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        {:reply,predecessor,{predecessor,successor,myHash,fingerNext,numRequests,fingerTable}}
    end

    # find successor
    def handle_call({:find_successor, id},  _from, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} ) do
        res = if (id > myHash & id <= get_hash(successor)) do
            {successor, myHash}
        else
            cl_prec_node = get_closest_preceeding_node(self(), id)
            {successor, myHash} = find_successor(cl_prec_node, id)
        end

        {:reply, res, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} }

    end

    def handle_call({:closest_preceeding_node, id}, _from, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
         

    end

    #################### Handle_Casts #####################
    def handle_cast(:set_hash, {predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
      hash = :crypto.hash(:sha256,self()) |> Base.encode16(case: :lower) |> Integer.parse()
      {:noreply, {predecessor,successor,hash,fingerNext,numRequests,fingerTable}}  
    end

    def notify({:notify,newPredecessor},{main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        {:noreply, {main_pid,newPredecessor,successor,myHash,fingerNext,numRequests,fingerTable}}
    end


end