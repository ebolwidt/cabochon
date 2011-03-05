
module KernelExt
  
  def self.debug=(v)
    @debug = v
  end
  
  def self.debug?
    @debug
  end
  
  # Executes command; if the first argument of args is an array, will take that as a list of commands and executes the first one
  # that exists.
  def self.fork_exec(args, input)
    output = nil
    f = IO.popen("-", "rb+")
    
    if (f.nil?)
      if (args[0].is_a? Array)
        paths = args[0]
        i = paths.index { |p| File.exist?(p) }
        if (i.nil?)
          raise "Command not found: #{paths.join(',')}"
        end
        args[0] = paths[i]
      end
      exec_internal(*args)
    else 
      f.write(input)
      f.close_write
      output = f.read
    end
    output
  end
  
  # Executes command; if the first argument of args is an array, will take that as a list of commands and executes the first one
  # that exists.
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
        exec_internal(*args)
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
        exec_internal(*args)
      end
    end
  end
  
  private
  def self.exec_internal
    if (@debug)
      $stderr.puts("Executing: #{args.join(' ')}")
    end
    Kernel.exec(*args)
  end
end
