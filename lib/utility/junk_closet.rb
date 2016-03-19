class JunkCloset
	
	def self.puts_helper(start_str, identifier, value)
	  if start_str == ""
	    return identifier + ": " + value
	  else
	    return start_str + " " + identifier + ": " + value
	  end    
	end

end