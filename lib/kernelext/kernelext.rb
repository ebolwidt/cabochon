
module KernelExt
  def self.fork_exec_get_output(*args)
    output = nil
    IO.popen("-") do |f| 
      if (f.nil?)
        Kernel.exec(*args) 
      else 
        output = f.read
      end
    end
    output
  end
  
  def self.fork_exec_no_output(*args)
    # A way to send output to the bitbucket
    IO.popen("-") do |f| 
      if (f.nil?)
        Kernel.exec(*args)
      end
    end
  end
end