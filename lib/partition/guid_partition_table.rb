# TODO unpack("Q") is wrong, is native order, should be little endian order

require 'uuidtools'

class GuidPartitionTable
  attr_accessor :partitions, :new_table, :disk_guid
  
  def self.read(file)
    GuidPartitionTable.new.read(file)  
  end
  
  def self.new_table()
    p = GuidPartitionTable.new
    p.new_table = true
    p.disk_guid = UUIDTools::UUID.generate
    p.partitions = []
    p
  end
 
  def read(file)
#0   8 bytes   Signature ("EFI PART", 45 46 49 20 50 41 52 54)
#8   4 bytes   Revision (For version 1.0, the value is 00 00 01 00)
#12  4 bytes   Header size (in bytes, usually 5C 00 00 00 meaning 92 bytes)
#16  4 bytes   CRC32 of header (0 to header size), with this field zeroed during calculation
#20  4 bytes   Reserved; must be zero
#24  8 bytes   Current LBA (location of this header copy)
#32  8 bytes   Backup LBA (location of the other header copy)
#40  8 bytes   First usable LBA for partitions (primary partition table last LBA + 1)
#48  8 bytes   Last usable LBA (secondary partition table first LBA - 1)
#56  16 bytes  Disk GUID (also referred as UUID on UNIXes)
#72  8 bytes   Partition entries starting LBA (always 2 in primary copy)
#80  4 bytes   Number of partition entries
#84  4 bytes   Size of a partition entry (usually 128)
#88  4 bytes   CRC32 of partition array
#92  *   Reserved; must be zeroes for the rest of the block (420 bytes for a 512-byte LBA)
    @partitions = []
    header = read_header(file)
    @disk_guid = UUIDTools::UUID.parse_raw_le(header[56,16])
    entry_start_lba = header[72,8].unpack("Q")[0]
    num_entries = header[80,4].unpack("V")[0]
    entry_length = header[84,4].unpack("V")[0]
    
    
    file.seek(entry_start_lba * 512)
    0.upto(num_entries - 1) do
      entry_bytes = file.read(entry_length)
      partition = GuidPartition.from_b(entry_bytes)
      @partitions.push(partition)
    end
    self
  end
 
  def read_header(file)
    if (file.stat.size < 1024)
      raise "Invalid disk, size smaller than 2 blocks"
    end
    file.seek(512)
    header = file.read(512)
    
    header
  end
  
  def used_partitions
    partitions.reject { |p| p.empty? }
  end
  
  def to_s
    s = "GuidPartitionTable Disk Guid #{disk_guid}"
    partitions.each do |p|
      s << "\n\t#{p}" unless p.empty?
    end
    s
  end
end