$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'

require 'uuidtools'
require 'partition'

class Partition
  Type_Linux_Data = 1
  Type_Linux_Swap = 2
  
  attr_accessor :size, :type, :name, :mount
  
  def initialize(size, type, name, mount)
    @size = size
    @type = type
    @name = name
    @mount = mount
  end
end

class Partitioner
  attr_accessor :partitions
  
  def initialize(partitions)
    @partitions = partitions
  end
  
  def to_mbr_partition_table
    
  end
  
  def to_guid_partition_table
    
  end
end

class Autovac
  attr_accessor :image_size, :root_partition_size, :boot_partition_size
  
  def initialize(path, image_size, root_partition_size, boot_partition_size)
    @path = path
    @image_size = image_size
    @root_partition_size = root_partition_size
    @boot_partition_size = boot_partition_size
  end
  
  def create_image
    File.create_empty(@path, @image_size)
    partitioner = build_partitioner
    File.open(@path, "rb+") do |file|
      partitioner.to_mbr_partition_table.write(file)
    end
  end
  
  def mount
    raise 'Not implemented'
  end
  
  def bootstrap
    raise 'Not implemented'
  end
  
  def additional
    raise 'Not implemented'
  end
  
  def puppet
    raise 'Not implemented'
  end
  
  def make_bootable
    raise 'Not implemented'
  end
  
  def convert_to_vmx
    raise 'Not implemented'
  end
  
  def build_partitioner
    root_partition = Partition.new(@root_partition_size, Partition.Type_Linux_Data, "root", "/")
    boot_partition = Partition.new(@boot_partition_size, Partition.Type_Linux_Data, "boot", "/boot")
    Partitioner.new([root_partition, boot_partition])
  end
end

autovac = Autovac.new("tmp/myimg.img", SiSize::parse("500M"), SiSize::parse("400M"), SiSize::parse("99M"))
autovac.create_image
autovac.mount
autovac.bootstrap
autovac.additional
autovac.puppet
autovac.make_bootable
autovac.convert_to_vmx
