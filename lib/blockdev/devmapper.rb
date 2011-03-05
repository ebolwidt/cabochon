require 'kernelext/kernelext.rb'
require 'file/file_patch.rb'

module DevMapper
  @kpartx_path = "/sbin/kpartx"
  @dmsetup_path = "/sbin/dmsetup"
  @hdiutil_path = "/usr/bin/hdiutil"
  
  class Mapping
    attr_accessor :path, :device, :partition_devices, :block_devices
    
    def initialize(_path, pdevice = nil, ppartition_devices = [], pblock_devices = [])
      _path = _path.path if (_path.is_a? File)
      @path = path      
      @device = pdevice
      @partition_devices = ppartition_devices
      @block_devices = pblock_devices
    end
    
    def to_s
      "DevMapper::Mapping path=#{@path} device=#{@device} partition_devices=[#{@partition_devices.join(', ')}]"
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

  def self.get_mapping(path)
    if (file.is_a? File)
      file = file.path
    end
    output = KernelExt::fork_exec_get_output(@kpartx_path, file) 
    mapping = Mapping.new(file)
    output.scan /^(\S+)\s*:\s*\d+\s+\d+\s+(\S+)\s+\d+$/ do |m|
      if (mapping.device.nil?)
        mapping.device = $2
      end
      mapping.block_devices.push($2)
      mapping.partition_devices.push("/dev/mapper/" + $1)
    end
    # Some versions of kpartx generate a line for the extended partition itself. We must drop it, since it is not always generated
    # Worse, some kpartx versions contain a bug, where the block device of a logical partition doesn't point to the extended partition but
    # to another primary partition (number 3 when extended partition is number 4)
    if (mapping.partition_devices.length > 4)
      if (mapping.block_devices[3].match(/^\//))
        mapping.partition_devices.slice!(3)
        mapping.block_devices.slice!(3)
      end
    end
    mapping
  end
  
  private
  
  def self.map_partitions_to_devices_kpartx(path)
    path = path.path if (path.is_a? File)
    loop_dev = Loop::add(path)
    KernelExt::fork_exec_get_output(@kpartx_path, "-a", loop_dev)
    get_mapping(loop_dev)
  end
  
  def self.unmap_partitions_to_devices_kpartx(path)
    path = path.path if (path.is_a? File)
    devices = Loop::devices_for(path)
    devices.each do |device|
      KernelExt::fork_exec_no_output(@kpartx_path, "-d", device)
      Loop::remove(device)
    end
  end
  
  def self.map_partitions_to_devices_hdiutil(file)
    output = KernelExt::fork_exec_get_output(@hdiutil_path, "attach", "-nomount", file.path)
    mapping = Mapping.new(file)
    output.scan /^(\S+)\s*/ do |m|
      mapping.partition_devices.push($1)
    end
    mapping.device = mapping.partition_devices.slice!(0)
    mapping
  end
  
  def self.unmap_partitions_to_devices_hdiutil(mapping)
    KernelExt::fork_exec_no_output(@hdiutil_path, "detach", mapping.device)
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
