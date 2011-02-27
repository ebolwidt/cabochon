class File
  attr_accessor :debug
  
  def seek_sector(sector_offset, purpose = nil)
    if (!sector_offset.nil?)
      if (debug)
        $stdout.puts "Seek to #{purpose} on #{sector_offset}"
      end
      seek(512*sector_offset)
    end
  end
  
  def read_sector(sector_offset = nil)
    seek_sector(sector_offset)
    r = read(512)
    if (r.nil? || r.length != 512)
      raise "Invalid sector read returned insufficient bytes"
    end
    r
  end
  
  def write_sector(bytes, sector_offset = nil)
    if (bytes.nil? || bytes.length != 512)
      raise "Invalid sector to write size is #{bytes.length} instead of 512"
    end
    seek_sector(sector_offset)
    w = write(bytes)
    if (w != 512)
      raise "Invalid sector write wrote only #{w} bytes"
    end
  end
end
