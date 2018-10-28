num_args = length(System.argv)
if (num_args != 2) do
    IO.puts "Invalid arguments \n args: num_nodes num_requests"
    exit(:shutdown)
end

#take commandline inputs
num_nodes = String.to_integer(List.first(System.argv))
num_requests = String.to_integer(List.last(System.argv))

main_pid = MainActor.start_up({0,num_nodes,0})
IO.puts "Spawned main"
IO.inspect main_pid
IO.puts "******************************"

all_pids = MainActor.create_ring(main_pid,num_nodes,num_requests)

IO.puts "Created ring"

Enum.each(all_pids, fn(x) -> ChordActor.search_keys_periodically(x) end)
MainActor.simulate(main_pid)
