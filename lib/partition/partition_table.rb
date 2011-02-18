
class PartitionTable
  attr_accessor :partitions, :new_table
  
  def self.read(file)
    PartitionTable.new.read(file)  
  end
  
  def self.new_table()
    p = PartitionTable.new
    p.new_table = true
    p.partitions = []
    p
  end
 
  def read(file)
    mbr = read_mbr(file)
    @partitions = []
    for i in 0 .. 3
      partition = Partition.from_b(mbr[446 + i * 16,16])
      if (partition.extended?)
        partition.read_extended(file)
      end
      if (partition.empty?)
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
    if (extended)
      extended.write_extended(file)
    end
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
      if (partitions.length > i && !partitions[i].nil? && !partitions[i].empty?)
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
    if (@partitions.select {|p| !p.nil? && p.extended? }.length > 1)
      raise "There is more than 1 extended partition"
    end
  end

  def extended
    @partitions.each do |p|
      if (!p.nil? && p.extended?)
        return p
      end
    end
    nil
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