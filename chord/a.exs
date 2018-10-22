a = 10

b = case a do
	nil -> IO.puts "a is nil"
    	_ -> IO.puts "a is not nil"
	end

IO.puts b
