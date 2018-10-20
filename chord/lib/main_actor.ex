defmodule MainActor do

    use GenServer
    ##################### state #####################
    #{total_hops,num_nodes, num_nodes_done}
    #################################################

    def start_up(default) do
      {:ok,main_pid} = GenServer.start_link(__MODULE__, default)
      main_pid
    end


    #spawn nodes and create init all the nodes with their fingertables
    def create_ring(main_pid,num_nodes, num_requests) do
        first_node = create_chord_worker(main_pid,num_requests)
        {ok, actors} = Enum.map(Enum.to_list(2..num_nodes), fn(x) -> 
                            worker_node = create_chord_worker(main_pid,num_requests)
                            ChordActor.join(worker_node, first_node)
                            worker_node
                        end )|> Enum.unzip
        first_node ++ actors
    end

    # find key
    def search() do
        GenServer.call(self,:search)
    end

    def simulate(pid) do
        {status,avgHops} = GenServer.call(pid,:check_status)
        if status==false do 
            simulate(pid) 
        else 
            IO.puts "DONE DONE DONE with #{avgHops}!!" end
    end

    #default state holds count=0 and empty finger-table
    #{predecessor,successor,myHash,fingerNext,numRequests,fingerTable(hashList, successorList)}
    def create_chord_worker(main_pid,num_requests) do
        { :ok, worker_pid} = ChordActor.start_link({main_pid, nil, nil,0,0,0,num_requests, [], []})
        ChordActor.set_hash(worker_pid)
        worker_pid
    end

    

    def handle_cast({:done,numHops}, {totalHops,num_nodes, num_nodes_done} ) do
        if (num_nodes_done + 1 == num_nodes) do
            IO.puts "all done!!!"
        end
        {:noreply, {totalHops+numHops,num_nodes, num_nodes_done+1}}
    end

    def handle_call(:search,_from,{totalHops,num_nodes, num_nodes_done}) do
        
    end
   
   def handle_call(:check_status,_from,{total_hops,num_nodes, num_nodes_done}) do
        done = if(num_nodes == num_nodes_done) do 
                true 
            else 
                false 
            end
        {:reply,{done,total_hops/num_nodes},{total_hops,num_nodes, num_nodes_done}}
    end

end