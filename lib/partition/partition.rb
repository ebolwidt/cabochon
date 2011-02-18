
class Partition
  # Takes 16 bytes of MS-DOS primary partition information
  attr_accessor :status, :type, :lba_start, :lba_length, :chs_start, :chs_end, :partitions, :parent
  
  def self.create(type, lba_start, lba_length)
    p = Partition.new
    p.type, p.lba_start, p.lba_length = type, lba_start, lba_length
    p.status, p.chs_start, p.chs_end, p.partitions = 0, CHS.new, CHS.new, []
    p
  end
  
  def self.from_b(bytes)
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
      logical = Partition.from_b(ebr[446, 16])
      logical.parent = self
      @partitions.push(logical)
      next_ebr = Partition.from_b(ebr[462, 16])
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
      ebr = create_ebr
      ebr[446, 16] = logical.to_b
      if (i + 1 < partitions.length)
        next_logical = partitions[i + 1]
        logical_lba_end = logical.lba_start + logical.lba_length - 1
        if (next_logical.lba_start <= logical_lba_end)
          raise "No space for additional EBR between logical partitions"
        end
        ebr[462, 16] = create_ebr_pointer(logical_lba_end + 1, next_logical)
        offset = (lba_start + logical_lba_end + 1) * 512
      else            
        ebr[462, 16] = "\0" * 16
      end
      file.write(ebr)
    end
  end
  
  def create_ebr_pointer(ebr_lba, logical)
    bytes = "\0" * 16
    bytes[0] = 0 # status
    bytes[1,3] = CHS.new.to_b
    bytes[4] = 0x05 # extended
    bytes[5,3] = CHS.new.to_b
    bytes[8,4] = [ebr_lba].pack("V")
    bytes[12,4] = [logical.lba_start + logical.lba_length - ebr_lba].pack("V")
    bytes
  end
  
  # Creates a new, empty EBR
  def create_ebr
    ebr = "\0" * 512
    ebr[510,2] = [ 0xAA55 ].pack("v")
    ebr
  end
  
  def to_s
    s = "Partition Type #{@type} status #{@status} lba_start #{@lba_start} lba_length #{@lba_length} chs_start [#{@chs_start}] chs_end [#{@chs_end}]"
    if (extended?)
      partitions.each {|p| s << "\n\t %s" % p}
    end
    s
  end
end

