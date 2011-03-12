# High-level partitions

require 'fileutils'
require 'partition'
require 'imgfile/imgfile.rb'
require 'blockdev/devmapper.rb'
require 'newfs/newfs.rb'
require 'mount/mount.rb'
require 'file/file_patch.rb'

# High-level partitions can be created on both MBR and GUID partition tables
# They know how to lay themselves out on the disk
# They also know how to devmap, newfs and mount themselves

class PartitionTable
  # Size of disk in sectors (after layout)
  attr_accessor :size
  attr_accessor :partitions
  # "gpt" or "mbr"
  attr_accessor :type
  attr_accessor :gpt_table_sectors, :mbr_table_sectors
  
  attr_accessor :path
  
  # Mount path for the entire image
  attr_accessor :mount_path
  
  def initialize
    @partitions = []
    @type = "gpt"
    @gpt_table_sectors = 34
    @mbr_table_sectors = 1
  end
  
  def root_partition
    @partitions.each do |p|
      if (!p.nil? && p.mount_point == '/')
        return p
      end
    end
    nil  
  end
  
  # Mount the root of the file system to mount_path
  def mount(mount_path)
    @mount_path = mount_path
    
    root = root_partition
    if (root.nil?)
      raise "No root partition"
    end
    Mount::mount(root.device, mount_path)
    root.mount_path = mount_path
    @partitions.each do |partition|
      partition_mount_path = mount_path + "/" + partition.mount_point
      File.ensure_dir(partition_mount_path)
      if (root != partition)
        Mount::mount(partition.device, partition_mount_path)
        partition.mount_path = partition_mount_path
      end
    end
  end
  
  # Mount the root of the file system to mount_path
  def dry_mount(mount_path)
    @mount_path = mount_path
    
    root = root_partition
    if (root.nil?)
      raise "No root partition"
    end
    root.mount_path = mount_path
    @partitions.each do |partition|
      partition_mount_path = mount_path + "/" + partition.mount_point
      if (root != partition)
        partition.mount_path = partition_mount_path
      end
    end
  end
  
  def unmount
    @partitions.reverse.each do |partition|
      Mount::unmount(partition.mount_path)
    end
  end
  
  def to_fstab
    
  end
  
  def map_partitions_to_devices
    if (@path.nil?)
      raise "No path known, use create_image or set path manually"
    end
    @mapping = DevMapper::map_partitions_to_devices(@path)
    if (@mapping.partition_devices.length != partitions.length)
      DevMapper::unmap_partitions_to_devices(@path)
      raise "Failed to map correctly number of partitions from devmapper (#{@mapping.partition_devices.length}) " +
            "doesn't match partititions defined in this table (#{partitions.length})"
    end
    0.upto(partitions.length - 1) do |i|
      device = @mapping.partition_devices[i]
      # Now fix up device in /dev/mapper - copy it to /dev
      if (device.match(/^\/dev\/mapper\/(.*)$/))
        new_device = "/dev/mpr#{$1}"
        FileUtils::cp_r(device, new_device)
        device = new_device
      end
      partitions[i].device = device
    end
  end
  
  def unmap_partitions_to_devices
    if (@mapping.nil?)
      @mapping = DevMapper::get_mapping(@path) 
    end
    DevMapper::unmap_partitions_to_devices(@mapping)
  end
  
  def newfs_partitions
    partitions.each do |partition|
      partition.newfs
    end
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
      mbr.partitions.push(mbr_partition)
    end
    last_sector = primaries[primaries.length - 1].sector_end + 1
    if (partitions.length > 4)
      mbr.partitions.push(create_mbr_extended_partition(partitions[3,partitions.length - 3], last_sector, align_on_multiples))
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
    File::create_empty(file, 512 * size)
    if (file.is_a? String)
      File.open(file, "rb+") { |f| low_level_table.write(f) }
      @path = file
    else
      low_level_table.write(file)
      @path = file.path
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
  
  def create_mbr_extended_partition(partitions, first_sector, gap)
    last_partition = partitions[partitions.length - 1]
    extended_partition = MbrPartition.create(0x0f, first_sector, last_partition.sector_end - first_sector + 1)
    partitions.each do |partition|
      logical_partition = MbrPartition.create(partition.type_mbr, gap, partition.size)
      logical_partition.parent = extended_partition
      extended_partition.partitions.push(logical_partition)
    end
    extended_partition
  end
  
end
