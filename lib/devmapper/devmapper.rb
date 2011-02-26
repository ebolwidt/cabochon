
require 'pipe-run'

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
  
  # TODO: pass arguments to kpartx one by one instead of one string; now we can't pass file names with spaces in them
  def self.map_partitions_to_devices_kpartx(file)
    output = Pipe.run("#{@kpartx_path} #{file.path}")
    mapping = Mapping.new(file)
    
    output.scan /^(\S+)\s*:\s*\d+\s+\d+\s+(\S+)\s+\d+$/ do |m|
      mapping.device = $2
      mapping.partition_devices.push("/dev/mapper/" + $1)
    end
    mapping
  end
  
  def self.unmap_partitions_to_devices_kpartx(mapping)
    output = Pipe.run("#{@kpartx_path} -d #{mapping.device}")
    puts(output)
  end
  
  def self.map_partitions_to_devices_hdiutil(file)
    output = Pipe.run("#{@hdiutil_path} attach -nomount #{file.path}")
    mapping = Mapping.new(file)
    output.scan /^(\S+)\s*/ do |m|
      mapping.partition_devices.push($1)
    end
    mapping.device = mapping.partition_devices.slice!(0)
    mapping
  end
  
  def self.unmap_partitions_to_devices_hdiutil(mapping)
    output = Pipe.run("#{@hdiutil_path} detach #{mapping.device}")
    puts(output)
  end
end