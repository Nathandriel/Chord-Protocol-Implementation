num_args = length(System.argv)
if (num_args != 2) do
    IO.puts "Invalid arguments \n args: num_nodes num_requests"
    exit(:shutdown)
end

#take commandline inputs
num_nodes = String.to_integer(List.first(System.argv))
num_requests = String.to_integer(List.first(System.argv))

main_pid = MainActor.start_up({0,num_nodes,0})
all_pids = MainActor.create_ring(main_pid,num_nodes,num_requests)
Enum.each(all_pids,fn(x)->ChordActor.stabilize_and_fix_fingers(x) end)
Enum.each(all_pids,fn(x)->ChordActor.search_keys_periodically(x) end)
MainActor.simulate(main_pid)
# {st,hibernate_actor_pid} = HibernateStatusActor.start_link({0,num_nodes})
# main_pid = A2.start_up(hibernate_actor_pid,num_nodes, topology, algorithm)
