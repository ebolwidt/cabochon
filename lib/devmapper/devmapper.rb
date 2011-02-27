require "kernelext/kernelext.rb"

module DevMapper
  @kpartx_path = "/sbin/kpartx"
  @hdiutil_path = "/usr/bin/hdiutil"
  
  
  class Mapping
    attr_accessor :file, :device, :partition_devices, :block_devices
    
    def initialize(pfile, pdevice = nil, ppartition_devices = [], pblock_devices = [])
      if (pfile.is_a? File)
        @file = pfile.path
      else
        @file = pfile
      end
      @device = pdevice
      @partition_devices = ppartition_devices
      @block_devices = pblock_devices
    end
    
    def to_s
      "DevMapper::Mapping file=#{@file.path} device=#{@device} partition_devices=[#{@partition_devices.join(', ')}]"
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
    if (file.is_a? File)
      file = file.path
    end
    KernelExt::fork_exec_get_output(@kpartx_path, "-a", file)
    get_mapping(file)
  end
  
  def self.get_mapping(file)
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
  
  
  def self.unmap_partitions_to_devices_kpartx(mapping)
    KernelExt::fork_exec_no_output(@kpartx_path, "-d", mapping.device)
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
  
  private
  
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