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
    def notify(pid) do
        ChordActor.cast(pid,:notify)
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
        
        #if count < @limit do
        self = self()
        Process.send_after(self,:stabalize, @time_interval)
        #end 

        { :noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable} }
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

    #################### Handle_Casts #####################
    def handle_cast(:set_hash, {predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
      hash = :crypto.hash(:sha256,self()) |> Base.encode16(case: :lower)
      {:noreply, {predecessor,successor,hash,fingerNext,numRequests,fingerTable}}  
    end

    def notify(:notify,{main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}) do
        {:noreply, {main_pid,predecessor,successor,myHash,fingerNext,numRequests,fingerTable}}
    end


end