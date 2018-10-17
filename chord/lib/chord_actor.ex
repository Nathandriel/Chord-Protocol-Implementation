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
  
    def get_successor(hash)do
      {successorPid, successorHash} = GenServer.call(pid,:get_successor)
    end

    def set_hash() do
      ChordActor.cast(:set_hash)
    end

    def get_hash(pid) do
     {status,hash} = ChordActor.call(pid,:get_hash)
    end

    # stabalize
    def stabalize() do
        Process.send_after(self,:stabalize, @time_interval)
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
        ChordActor.cast(sendTo,{:notify,sendThis})
    end

    #join
    def join(pid) do
        ChordActor.call(pid,:join)
    end

    # Server Side (callbacks)
    def init(default) do
      {:ok, default}
    end



    #################### Handle_Info #####################
    def handle_info(:stabalize, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        
        x = successor.get_predecessor()
        xHash = x.get_hash()
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
        Process.send_after(self,:stabalize, @time_interval)
        updatedState
        
    end
    
    def handle_info(:fix_fingers, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        
        #if count < @limit do
        self = self()
        Process.send_after(self,:fix_fingers, @time_interval)
        #end 

        { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} }
    end

    def handle_info(:check_predecessor, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        
        #if count < @limit do
        self = self()
        Process.send_after(self,:check_predecessor, @time_interval)
        #end 

        { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} }
    end


    #################### Handle_Call #####################
    # create
    def handle_call(:create, _from, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        {:noreply,{main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}}
    end


    # join
    def handle_call({:join,keyHash},  _from, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        #TODO
    end

    # get a pid's hash
    def handle_cast(:get_hash, _from, {predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        {:reply,myHash,{predecessor,successor,myHash,fingerNext,numRequests,fingerTable}}
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