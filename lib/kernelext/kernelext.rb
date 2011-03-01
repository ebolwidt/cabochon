
module KernelExt
  
  def self.fork_exec(args, input)
    output = nil
    f = IO.popen("-")
    
    if (f.nil?)
      if (args[0].is_a? Array)
        paths = args[0]
        i = paths.index { |p| File.exist?(p) }
        if (i.nil?)
          raise "Command not found: #{paths.join(',')}"
        end
        args[0] = paths[i]
      end
      Kernel.exec(*args)
    else 
      f.write(input)
      output = f.read
    end
    output
  end
  
  def self.fork_exec_get_output(*args)
    output = nil
    IO.popen("-") do |f| 
      if (f.nil?)
        if (args[0].is_a? Array)
          paths = args[0]
          i = paths.index { |p| File.exist?(p) }
          if (i.nil?)
            raise "Command not found: #{paths.join(',')}"
          end
          args[0] = paths[i]
        end
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