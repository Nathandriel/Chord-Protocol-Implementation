defmodule MainActor do

    use GenServer

    #spawn nodes and create init all the nodes with their fingertables
    def spawnActors(num_nodes) do
        {ok, actors} = Enum.map(Enum.to_list(1..num_nodes), fn(x) -> createChordWorkers(main_pid) end) |> Enum.unzip
        actors
    end

    #default state holds count=0 and empty finger-table
    def createChordWorkers() do
        ChordActor.start_link({0,[]})
    end

    #settingPeers
    def setPeers() do

    end

    #initial chord assignment
    def initChord() do

    end


end