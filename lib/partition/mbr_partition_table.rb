# encoding: utf-8

#  Copyright (C) 2011 Erwin Bolwidt <ebolwidt@worldturner.com>

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public License
#  along with this program in the file COPYING.
#  If not, see <http://www.gnu.org/licenses/>.

class MbrPartitionTable
  attr_accessor :partitions, :new_table, :disk_signature
  
  def to_s
    s = "MbrPartitionTable"
    partitions.each do |partition|
      s << "\n\t#{partition}"
    end
    s
  end
  def self.read(file)
    MbrPartitionTable.new.read(file)  
  end
  
  def self.new_table()
    p = MbrPartitionTable.new
    p.new_table = true
    p.disk_signature = rand(1<<32) & 0xffffffff
    p.partitions = []
    p
  end
  
  def read(file)
    mbr = read_mbr(file)
    @disk_signature = mbr[440,4].unpack("V")[0]
    @partitions = []
    for i in 0 .. 3
      partition = MbrPartition.from_b(mbr[446 + i * 16,16])
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
  
  # Convert to bytes as if this was a new MBR
  def to_b
    mbr = MbrPartitionTable.create_mbr
    update_mbr(mbr)
    mbr
  end
  
  # Dangerous! Don't allow people to write to block devices until they turn on a certain flag/option or something
  def write(file)
    sanity_check
    
    if (@new_table)
      mbr = MbrPartitionTable.create_mbr
    else
      mbr = read_mbr(file)
    end
    
    update_mbr(mbr)

    file.write_sector(mbr, 0)
    
    if (extended)
      extended.write_extended(file)
    end
  end
  
  # Creates a new, empty MBR
  def self.create_mbr
    mbr = "\0" * 512
    mbr[510,2] = [ 0xAA55 ].pack("v")
    mbr
  end
  
  def update_mbr(mbr)
    mbr[440,4] = [disk_signature].pack("V")
    for i in 0 .. 3
      if (partitions.length > i && !partitions[i].nil? && !partitions[i].empty?)
        mbr[446 + i * 16, 16] = partitions[i].to_b
      else
        mbr[446 + i * 16, 16] = "\0" * 16
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
    mbr = file.read_sector(0)
    mbr_signature = mbr[510,2].unpack("v")[0]
    if (mbr_signature != 0xAA55)
      raise "Invalid MBR signature for MS-DOS disklabel: #{mbr_signature}"
    end
    mbr
  end

  def self.mbr?(path)
    File.open(path, "rb") do |file|
      mbr = file.read_sector(0)
      mbr_signature = mbr[510,2].unpack("v")[0]
      mbr_signature == 0xAA55
    end
  end

end
