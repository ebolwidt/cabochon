# High-level partitions

require 'partition'
require 'imgfile/imgfile.rb'

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
end

class PartitionTable
  # Size of disk in sectors (after layout)
  attr_accessor :size
  attr_accessor :partitions
  # "gpt" or "mbr"
  attr_accessor :type
  attr_accessor :gpt_table_sectors, :mbr_table_sectors
  
  def initialize
    @partitions = []
    @type = "gpt"
    @gpt_table_sectors = 34
    @mbr_table_sectors = 1
  end
  
  def to_fstab
    
  end
  
  def layout(align_on_multiples=4, first_sector=64)
    case type
      when 'gpt', 'GPT' then
      layout_gpt(align_on_multiples, first_sector)
      when 'mbr', 'MBR' then
      layout_mbr(align_on_multiples, first_sector)
    else
      raise "Unknown partition table type #{type}"
    end
  end
  
  def layout_mbr(align_on_multiples=4, first_sector=64)
    primaries = nil
    if (partitions.length <= 4)
      primaries = partitions
    else
      primaries = partitions[0,3]
    end
    
    @size = layout_start_end(primaries, align_on_multiples, first_sector)
    if (partitions.length > 4)
      @size = layout_start_end(partitions[3,partitions.length - 3], align_on_multiples, @size, align_on_multiples)
    end
    
    mbr = MbrPartitionTable.new_table
    primaries.each do |partition|
      mbr_partition = MbrPartition.create(partition.type_mbr, partition.sector_start, partition.size)
      partition.unique_id = guid_partition.unique_id
      gpt.partitions.push(p)
    end
    last_sector = primaries[primaries.length - 1].sector_end + 1
    if (partitions.length > 4)
      gpt.partitions.push(create_mbr_extended_partition(partitions[3,partitions.length - 3], last_sector))
    end
    mbr
  end
  
  def layout_gpt(align_on_multiples=4, first_sector=64)
    if (first_sector < @gpt_table_sectors)
      raise "First sector should be at least #{@gpt_table_sectors} to allow for GUID partition table"
    end
    # Append @gpt_table_sectors for backup table
    @size = layout_start_end(partitions, align_on_multiples, first_sector) + @gpt_table_sectors
    
    gpt = GuidPartitionTable.new_table
    partitions.each do |partition|
      guid_partition = GuidPartition.create(partition.type_guid, partition.sector_start, partition.sector_end, partition.name)
      partition.unique_guid = guid_partition.unique_guid
      gpt.partitions.push(guid_partition)
    end
    gpt
  end
  
  # Pass in a file and the result of layout_gpt or layout_mbr
  def create_image(file, low_level_table = nil)
    if (low_level_table.nil?)
      low_level_table = layout
    end
    puts(low_level_table)
    File::create_empty(file, 512 * size)
    if (file.is_a? String)
      file = File.open(file, "rb+") { |f| low_level_table.write(f) }
    else
      low_level_table.write(file)
    end
  end
  
  def to_s
    s = "PartitionTable size #{@size}"
    partitions.each do |p|
      s << "\n\t #{p}"
    end
    s
  end
  
  private
  
  def layout_start_end(partitions, align_on_multiples, first_sector, gap=0)
    # First sector for a partition
    sector = first_sector
    next_sector = sector
    partitions.each do |partition|
      sector = sector + gap
      partition.sector_start = sector
      next_sector = sector + partition.size
      next_sector = ((next_sector + align_on_multiples - 1) / align_on_multiples).to_i * align_on_multiples
      partition.sector_end = next_sector - 1
      partition.size = partition.sector_end - partition.sector_start + 1
      sector = next_sector
    end
    next_sector
  end
  
  def create_mbr_extended_partition(partitions, first_sector)
    last_partition = partitions[partitions.length - 1]
    extended_partition = MbrPartition.create(0x15, first_sector, last_partition.sector_end - first_sector + 1)
    partitions.each do |partition|
      logical_partition = MbrPartition.create(0x05, partition.sector_start - first_sector, partition.size)
      logical_partition.parent = extended_partition
      extended_partition.partitions.push(logical_partitions)
    end
    extended_partition
  end
  
end