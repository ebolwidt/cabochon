
module KernelExt
  
  def self.debug=(v)
    @debug = v
  end
  
  def self.debug?
    @debug
  end
  
  def self.process_arguments(args)
    cmd = 0
    if (args[0].is_a? Hash)
      cmd = 1;
    end
    if (args[cmd].is_a? Array)
      paths = args[cmd]
      i = paths.index { |p| File.exist?(p) }
      if (i.nil?)
        raise "Command not found: #{paths.join(',')}"
      end
      args[cmd] = paths[i]
    end
    
  end
  
  # Executes command; if the first argument of args is an array, will take that as a list of commands and executes the first one
  # that exists.
  def self.fork_exec(args, input)
    process_arguments(args)
    output = nil
    f = IO.popen("-", "rb+")
    if (f.nil?)
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
    process_arguments(args)
    output = nil
    IO.popen("-") do |f| 
      if (f.nil?)        
        exec_internal(*args)
      else 
        output = f.read
      end
    end
    output
  end
  
  
  def self.fork_exec_no_output(*args)
    process_arguments(args)
    # A way to send output to the bitbucket
    IO.popen("-") do |f| 
      if (f.nil?)
        exec_internal(*args)
      end
    end
  end
  
  private
  def self.exec_internal(*args)
    if (@debug)
      $stderr.puts("Executing: #{args.join(' ')}")
    end
    Kernel.exec(*args)
  end
end
