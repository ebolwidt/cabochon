require 'kernelext/kernelext.rb'
require 'file/file_patch.rb'
require 'blockdev/loop.rb'

module DevMapper
  @kpartx_path = "/sbin/kpartx"
  @dmsetup_path = "/sbin/dmsetup"
  @hdiutil_path = "/usr/bin/hdiutil"
  
  @grub_workaround = true
  
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
  
  def self.unmap_partitions_to_devices(path)
    invoke_kpartx_or_hdiutil(proc { |args| unmap_partitions_to_devices_kpartx(*args) }, proc { |args| unmap_partitions_to_devices_hdiutil(*args) }, path)
  end
  
  def self.get_mapping(path)
    path = path.path if (path.is_a? File)
    output = KernelExt::fork_exec_get_output(@kpartx_path, path) 
    mapping = Mapping.new(path)
    output.scan /^(\S+)\s*:\s*\d+\s+\d+\s+(\S+)\s+\d+$/ do |m|
      if (mapping.device.nil?)
        mapping.device = $2
      end
      partition_device = "/dev/mapper/" + $1
      if (!MbrPartitionTable.mbr?(partition_device))
        if (@grub_workaround)
          # Now fix up device in /dev/mapper - copy it to /dev
          new_device = "/dev/mpr_#{$1}"
          # FileUtils::cp_r doesn't support devices
          output = KernelExt::fork_exec_get_output("/bin/cp", "-R", partition_device, new_device)
          partition_device = new_device
        end
        mapping.block_devices.push($2)
        mapping.partition_devices.push(partition_device)
      end
    end
    mapping
  end
  
  def self.unmount_partitions(path)
    path = path.path if (path.is_a? File)
    devices = Loop::devices_for(path)
    devices.each do |device|      
      mapping = get_mapping(device)
      mapping.partition_devices.reverse.each do |partition_device|
        if (@grub_workaround)
          if (partition_device.match(/^\/dev\/mapper\/(.*)$/))
            partition_device = "/dev/mpr_#{$1}"
          end
        end
        Mount::unmount(partition_device)
      end
    end
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
  
  #def self.unmap_partitions_to_devices_hdiutil(path)
  #  KernelExt::fork_exec_no_output(@hdiutil_path, "detach", mapping.device)
  #end
  
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
