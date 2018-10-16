defmodule ChordActor do
    use GenServer
  
    # Client Side
    def start_link(default) do
      GenServer.start_link(__MODULE__, default)
    end
  
    def get_successor(hash)do
      {successorPid, successorHash} = GenServer.call(pid,:get_successor)
    end
  
    # Server Side (callbacks)
    def init(default) do
      {:ok, default}
    end

    def find(keyHash,pid) do
      ChordActor.call(pid,{:find,keyHash})
    end
  
    #################### Handle_Call #####################
    # get sucessor
    def handle_call(:get_successor, _from, {myHash, requestCount, fingerTable}) do
        {:reply,fingerTable[0],{myHash,requestCount, fingerTable}}
    end

    #################### Handle_Casts #####################
    
    # hibernate
    def handle_call({:find,keyHash},  _from, {myHash, requestCount, fingerTable}) do
        #check if successor greater than keyHash, if yes return successor
        {successorHash,successorPid} = fingerTable[0]
        if (successorHash > keyHash) || (successorHash < myHash) do
            {:reply,fingerTable[0],{myHash,requestCount+1,fingerTable}}
        else
            #find predecessor

            #make a call to it
        end
        
    end

end