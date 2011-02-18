
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
    file.seek(offset)
    
    begin
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
        file.seek(offset)
      end
    end while !next_ebr.empty?
  end
  
  def to_s
    s = "Partition Type #{@type} status #{@status} lba_start #{@lba_start} end_lba #{@lba_length} chs_start [#{@chs_start}] chs_end [#{@chs_end}]"
    if (extended?)
      partitions.each {|p| s << "\n\t %s" % p}
    end
    s
  end
end

