num_args = length(System.argv)
if (num_args != 2) do
    IO.puts "Invalid arguments \n args: num_nodes num_requests"
    exit(:shutdown)
end

#take commandline inputs
num_nodes = String.to_integer(List.first(System.argv))
num_requests = String.to_integer(List.first(System.argv))
# {st,hibernate_actor_pid} = HibernateStatusActor.start_link({0,num_nodes})
# main_pid = A2.start_up(hibernate_actor_pid,num_nodes, topology, algorithm)
