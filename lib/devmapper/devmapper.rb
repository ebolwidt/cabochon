
module DevMapper
  @kpartx_path = "/sbin/kpartx"
  @hdiutil_path = "/usr/bin/hdiutil"
  
  
  class Mapping
    attr_accessor :file, :device, :partition_devices
    
    def initialize(pfile, pdevice = nil, ppartition_devices = [])
      @file = pfile
      @device = pdevice
      @partition_devices = ppartition_devices
    end
    
    def to_s
      "DevMapper::Mapping file=#{@file.path} device=#{@device} partitions_devices=[#{@partition_devices.join(', ')}]"
    end
  end

  # Maps the partitions in the image file to devices
  # Returns an array with the devices names for each partition
  def self.map_partitions_to_devices(file)
    if (file.is_a? String)
      file = File.new(file)
    end
    invoke_kpartx_or_hdiutil(proc { |args| map_partitions_to_devices_kpartx(*args) }, proc { |args| map_partitions_to_devices_hdiutil(*args) }, file)
  end
  
  def self.unmap_partitions_to_devices(mapping)
    invoke_kpartx_or_hdiutil(proc { |args| unmap_partitions_to_devices_kpartx(*args) }, proc { |args| unmap_partitions_to_devices_hdiutil(*args) }, mapping)
  end
  
  def self.map_partitions_to_devices_kpartx(file)
    output = fork_exec_get_output(@kpartx_path, file.path) 
    mapping = Mapping.new(file)
    
    output.scan /^(\S+)\s*:\s*\d+\s+\d+\s+(\S+)\s+\d+$/ do |m|
      mapping.device = $2
      mapping.partition_devices.push("/dev/mapper/" + $1)
    end
    mapping
  end
  
  
  def self.unmap_partitions_to_devices_kpartx(mapping)
    fork_exec_no_output(@kpartx_path, "-d", mapping.device)
  end
  
  def self.map_partitions_to_devices_hdiutil(file)
    output = fork_exec_get_output(@hdiutil_path, "attach", "-nomount", file.path)
    mapping = Mapping.new(file)
    output.scan /^(\S+)\s*/ do |m|
      mapping.partition_devices.push($1)
    end
    mapping.device = mapping.partition_devices.slice!(0)
    mapping
  end
  
  def self.unmap_partitions_to_devices_hdiutil(mapping)
    fork_exec_no_output(@hdiutil_path, "detach", mapping.device)
  end
  
  private
  
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
  
  # Check for availability of kpartx and hditool (MacOS) and select the right one
  def self.invoke_kpartx_or_hdiutil(func_kpartx, func_hdiutil, *args)
    if (File.exist?(@kpartx_path))
      func_kpartx.call(args)
    elsif (File.exist?(@hdiutil_path))
      func_hdiutil.call(args)
    else
      raise "kpartx and hdiutil not found"
    end
  end
end