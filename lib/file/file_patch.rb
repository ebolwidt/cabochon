
class File
  attr_accessor :debug

  # Returns size of file in bytes, or of block device if it is a block device.
  def size
    if stat.blockdev?
      blockdev_size
    else
      stat.size
    end
  end
  
  def blockdev_size
#    v = "\0" * 8
    v = "01234567"
    $stderr.puts(v.length)
    ioctl(0x80081272, v)
    v.unpack("Q")[0]
  end

  def self.ensure_dir(path)
    if (!File.directory? path)
      if (File.exist? path)
        raise "File #{path} exists but is not a directory"
      end
      # TODO: recursively create parts
      FileUtils::mkdir_p(path)
    end
  end
  
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
