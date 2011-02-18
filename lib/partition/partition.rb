class CHS
  attr_accessor :cylinder, :head, :sector
  
  def initialize(bytes)
    @head = bytes[0]
    @sector = bytes[1] & 0x3f
    @cylinder = ((bytes[1] & 0xc0) << 2) | bytes[2]
  end
  
  def to_b
    bytes = "\0" * 3
    bytes[0] = head
    bytes[1] = (sector & 0x3f) | ((cylinder >> 2) & 0xc0)
    bytes[2] = cylinder
    bytes
  end
  
  def to_s
    "Cylinder #{@cylinder} Head #{@head} Sector #{@sector}"
  end
end

class Partition
  # Takes 16 bytes of MS-DOS primary partition information
  attr_accessor :status, :type, :lba_start, :lba_length, :chs_start, :chs_end, :partitions
  
  def self.new_primary(bytes)
    p = Partition.new
    
    p.status = bytes[0]
    p.chs_start = CHS.new(bytes[1,3])
    p.type = bytes[4]
    p.chs_end = CHS.new(bytes[5,3])
    p.lba_start = bytes[8,4].unpack("V")[0]
    p.lba_length = bytes[12,4].unpack("V")[0]
    p
  end
  
    
  def to_b
    bytes = "\0" * 16
    bytes[0] = status
    bytes[1,3] = chs_start.to_b
    bytes[4] = type
    bytes[5,3] = chs_end.to_b
    bytes[8,4] = [lba_start].pack("V")
    bytes[12,4] = [lba_length].pack("V")
    puts "Bytes.length in Partiton %d" % bytes.length
    bytes
  end
  
  def is_empty?
    type == 0
  end
  
  def is_extended?
    type == 0x05 || type == 0x0f
  end
  
  def read_extended(file)
    @partitions = []
    offset = lba_start * 512
    file.seek(offset)
    
    begin
      ebr = file.read(512)  
      @partitions.push(Partition.new_primary(ebr[446, 16]))
      next_ebr = Partition.new_primary(ebr[462, 16])
      if (!next_ebr.is_empty?)
        offset = (next_ebr.lba_start + lba_start) * 512
        file.seek(offset)
      end
    end while !next_ebr.is_empty?
  end
  
  def to_s
    s = "Partition Type #{@type} status #{@status} lba_start #{@lba_start} end_lba #{@lba_length} chs_start [#{@chs_start}] chs_end [#{@chs_end}]"
    if (is_extended?)
      partitions.each {|p| s << "\n\t %s" % p}
    end
    s
  end
end

class PartitionTable
  attr_accessor :partitions, :new_table
  
  def self.read(file)
    PartitionTable.new.read(file)  
  end
  
  def self.new_table()
    p = PartitionTable.new
    p.new_table = true
    p
  end
 
  def read(file)
    mbr = read_mbr(file)
    @partitions = []
    for i in 0 .. 3
      partition = Partition.new_primary(mbr[446 + i * 16,16])
      if (partition.is_extended?)
        partition.read_extended(file)
      end
      if (partition.is_empty?)
        @partitions.push(nil)
      else
        @partitions.push(partition)
      end
    end
    self
  end
 
  # Dangerous! Don't allow people to write to block devices until they turn on a certain flag/option or something
  def write(file)
    if (@new_table)
      mbr = create_mbr
    else
      mbr = read_mbr(file)
    end
    
    overwrite_partitions(file, mbr)
  end
  
  # Creates a new, empty MBR
  def create_mbr
    mbr = "\0" * 512
    mbr[510,2] = [ 0xAA55 ].pack("v")
    mbr
  end
  
  # Needs an existing MBR - overwrite the partitions on it
  # Dangerous! Don't allow people to write to block devices until they turn on a certain flag/option or something
  def overwrite_partitions(file, mbr)
    sanity_check
    update_partitions(mbr)
    file.seek(0)
    file.write(mbr)
  end
  
  def update_partitions(mbr)
    for i in 0 .. 3
      if (partitions.length > i && !partitions[i].nil? && !partitions[i].is_empty?)
        mbr[446 + i * 16, 16] = partitions[i].to_b
      else
        for o in 0 .. 15
          mbr[446 + i * 16 + o ] = 0
        end
      end
    end
  end
  
  def sanity_check
    if (partitions.length > 4)
      raise "There are #{@partitions.length} primary partitions but there can't be more than 4"
    end
    if (@partitions.select {|p| !p.nil? && p.is_extended? }.length > 1)
      raise "There is more than 1 extended partition"
    end
  end
  
  def read_mbr(file)
    if (file.stat.size < 512)
      raise "Invalid disk, size smaller than 1 block"
    end
    file.seek(0)
    mbr = file.read(512)
    signature = mbr[510,2].unpack("v")[0]
    if (signature != 0xAA55)
      raise "Invalid MBR signature for MS-DOS disklabel: %x" % signature
    end
    mbr
  end
end