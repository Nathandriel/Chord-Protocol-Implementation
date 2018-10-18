defmodule MainActor do

    use GenServer

    #spawn nodes and create init all the nodes with their fingertables
    def spawnActors(num_nodes) do
        {ok, actors} = Enum.map(Enum.to_list(1..num_nodes), fn(x) -> createChordWorkers(main_pid) end) |> Enum.unzip
        actors
    end

    #default state holds count=0 and empty finger-table
    #{predecessor,successor,myHash,fingerNext,numRequests,fingerTable(hashList, successorList)}
    def createChordWorkers(main_pid) do
        worker_pid = ChordActor.start_link({main_pid, nil, nil,0,0,0, [], []})
        ChordActor.set_hash()
        worker_pid
    end

    

    def handle_cast(:done, {num_nodes, num_nodes_done} ) do
        if (num_nodes_done + 1 == num_nodes) do
            IO.puts "all done!!!"
        end
        {:noreply, {num_nodes, num_nodes_done+1}}
    end

   




end