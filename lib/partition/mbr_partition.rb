
class MbrPartition
  # Takes 16 bytes of MS-DOS primary partition information
  attr_accessor :status, :type, :lba_start, :lba_length, :chs_start, :chs_end, :partitions, :parent
  
  def self.create(type, lba_start, lba_length)
    p = MbrPartition.new
    p.type, p.lba_start, p.lba_length = type, lba_start, lba_length
    p.status, p.chs_start, p.chs_end, p.partitions = 0, CHS.from_lba(lba_start), CHS.from_lba(lba_start + lba_length - 1), []
    p
  end
  
  def self.from_b(bytes)
    p = MbrPartition.new
    
    p.status = bytes[0]
    p.chs_start = CHS.from_b(bytes[1,3])
    p.type = bytes[4]
    p.chs_end = CHS.from_b(bytes[5,3])
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
    bytes
  end
  
  def empty?
    type == 0
  end
  
  def extended?
    type == 0x05 || type == 0x0f
  end
  
  def read_extended(file)
    @partitions = []
    offset = lba_start * 512
    
    begin
      file.seek(offset)
      ebr = file.read(512)
      if (ebr.nil? || ebr.length != 512)
        raise "Problem lba_start = #{lba_start}, ebr = #{ebr.nil?}, offset = #{file.pos}"
      end
      logical = MbrPartition.from_b(ebr[446, 16])
      logical.parent = self
      @partitions.push(logical)
      next_ebr = MbrPartition.from_b(ebr[462, 16])
      if (!next_ebr.empty?)
        offset = (next_ebr.lba_start + lba_start) * 512
      end
    end while !next_ebr.empty?
  end
  
  def write_extended(file)
    offset = lba_start * 512
    
    for i in 0 .. partitions.length - 1
      file.seek(offset)
      logical = partitions[i]
      ebr = MbrPartitionTable.create_mbr
      ebr[446, 16] = logical.to_b
      if (i + 1 < partitions.length)
        next_logical = partitions[i + 1]
        logical_lba_end = logical.lba_start + logical.lba_length - 1
        ebr[462, 16] = create_ebr_pointer(logical_lba_end + 1, next_logical)
        offset = (lba_start + logical_lba_end + 1) * 512
      else            
        ebr[462, 16] = "\0" * 16
      end
      file.write(ebr)
    end
  end
  
  def create_ebr_pointer(ebr_lba, logical)
    ebr_lba_length = logical.lba_start + logical.lba_length
    bytes = "\0" * 16
    bytes[0] = 0 # status
    bytes[1,3] = CHS.from_lba(ebr_lba).to_b
    bytes[4] = 0x05 # extended
    bytes[5,3] = CHS.from_lba(ebr_lba + ebr_lba_length - 1).to_b
    bytes[8,4] = [ebr_lba].pack("V")
    bytes[12,4] = [ebr_lba_length].pack("V")
    bytes
  end
  
  def to_s
    s = "MbrPartition Type #{@type} status #{@status} lba_start #{@lba_start} lba_length #{@lba_length} " +
        "chs_start [#{@chs_start}] chs_end [#{@chs_end}]"
    if (extended?)
      partitions.each {|p| s << "\n\t %s" % p}
    end
    s
  end
end

