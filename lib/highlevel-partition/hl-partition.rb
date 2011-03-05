# High-level partitions

require 'partition'
require 'imgfile/imgfile.rb'
require 'blockdev/devmapper.rb'
require 'newfs/newfs.rb'
require 'mount/mount.rb'
require 'file/file_patch.rb'

# High-level partitions can be created on both MBR and GUID partition tables
# They know how to lay themselves out on the disk
# They also know how to devmap, newfs and mount themselves

class Partition
  Type_Linux_Data = 1
  Type_Linux_Swap = 2
  
  # Size in 512-byte sectors. May be adjusted by layout process
  attr_accessor :size
  # High-level type of partition
  attr_accessor :type
  # Where is the partition to be mounted in the file system
  attr_accessor :mount_point
  # Partition name (only for GPT) default to mount_point
  attr_accessor :name
  # File system type (or nil) like ext2, reiserfs, ext4
  attr_accessor :fs_type
  
  # Sector on disk on which the partition starts
  attr_accessor :sector_start, :sector_end
  
  # GUID assigned to partition
  attr_accessor :unique_guid
  # Device once partition has been device mapped
  attr_accessor :device
  # Mount path in the host file system once the partition has been mounted
  attr_accessor :mount_path
  
  def initialize(size, type, mount_point, fs_type)
    @size = size
    @type = type
    @mount_point = mount_point
    @fs_type = fs_type
  end
  
  def name
    if @name.nil? then @mount_point else @name end
  end
  
  def type_guid
    case type
      when Type_Linux_Data then
      UUIDTools::UUID.parse("41F65323-8371-4A45-B609-F071B694F0C0")
      when Type_Linux_Swap then
      UUIDTools::UUID.parse("1DB8B717-A626-4D85-A0A4-2F3B6ECF5956")
    end
  end
  
  def type_mbr
    case type
      when Type_Linux_Data then
      0x83
      when Type_Linux_Swap then
      0x82
    end
  end
  
  def to_s
    "Partition size #{size} type #{type} mount_point #{mount_point} name #{@name} fs_type #{fs_type} sector_start #{sector_start} sector_end #{sector_end}"
  end
  
  # Creates a new file system on this partition
  def newfs
    if (device.nil?)
      raise "Partition hasn't yet been mapped to a device"
    end
    if (fs_type.nil?)
      raise "No fs_type specified"
    end
    NewFs::newfs(device, fs_type)
  end
end
