class File
  def self.create_empty(path, size, sparse = true, overwrite = true)
    if (path.is_a? File)
      path = path.path
    end
    if (overwrite)
      mode = "wb+"
    else
      mode = "rb+"
    end
    File.open(path, mode) do |f|
      if (f.stat.size > size)
        f.truncate(size)
      elsif (sparse)
        f.seek(size - 1)
        f.write("\0")
      else
        b = "\0" * 4096
        while (size > b.length)
          size -= f.write(b)
        end
        while (size > 0)
          size -= f.write("\0")
        end    
      end
    end
  end
end