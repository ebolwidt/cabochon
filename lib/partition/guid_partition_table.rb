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


require 'uuidtools'

# Guid Partition Table header

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

class GuidPartitionTable
  # Signature that should appear at the start of sector 1 of the disk
  EfiSignature = [ 0x45, 0x46, 0x49, 0x20, 0x50, 0x41, 0x52, 0x54 ].pack("c*")
  # Default length of a partition entry - the length used when creating partition tables
  DefaultEntrySize = 128
  # Default number of partition entries - unused ones are zero-filled
  DefaultNumEntries = 128
  
  attr_accessor :partitions, :new_table, :disk_guid, :lba_first, :lba_last, :num_entries, :entry_size
  
  def self.read(file)
    GuidPartitionTable.new.read(file)  
  end
  
  def self.read_backup(file)
    disk_sectors = file.stat.size / 512
    GuidPartitionTable.new.read(file, disk_sectors - 1)
  end
  
  def self.new_table()
    p = GuidPartitionTable.new
    p.new_table = true
    p.disk_guid = UUIDTools::UUID.random_create
    p.partitions = []
    p
  end
  
  def read(file, lba_location = 1)
    @partitions = []
    header = read_header(file)
    @disk_guid = UUIDTools::UUID.parse_raw_le(header[56,16])
    entry_start_lba = header[72,8].unpack_64b_le_single
    @num_entries = header[80,4].unpack("V")[0]
    @entry_size = header[84,4].unpack("V")[0]
    
    
    file.seek(entry_start_lba * 512)
    0.upto(num_entries - 1) do
      entry_bytes = file.read(@entry_size)
      partition = GuidPartition.from_b(entry_bytes)
      @partitions.push(partition)
    end
    self
  end
  
  def write(file)
    if (@new_table)
      disk_sectors = file.stat.size / 512
      mbr = create_protective_mbr(disk_sectors)
      file.seek(0)
      file.write(mbr)
      
      @num_entries = DefaultNumEntries
      @entry_size = DefaultEntrySize
      @lba_first = 2 + (@num_entries * @entry_size) / 512
      backup_entries_lba = disk_sectors - 1 - (@num_entries * @entry_size) / 512
      @lba_last = backup_entries_lba - 1
      
      header = create_header(2, 1, disk_sectors - 1)
      backup_header = create_header(backup_entries_lba, disk_sectors - 1, 1)
    else
      header = read_header(file)
      backup_header = read_header(file, disk_sectors - 1)
    end
    
    # write header
    file.seek(512)
    file.write(header)
    
    # Write partition entries
    file.write(partition_entries_to_b)
    
    # Write backup partition entries
    file.seek(backup_entries_lba * 512)
    file.write(partition_entries_to_b)
    
    # write backup header
    file.seek((disk_sectors - 1) * 512)
    file.write(backup_header)
  end
  
  def create_protective_mbr(disk_sectors)
    mpt = MbrPartitionTable.new_table
    # Create a partition that covers the entire disk, of type 0xEE
    if (disk_sectors > (1 << 32))
      # If the disk is larger than 2Tib, then the MBR can't handle it and will protect only the first 2Tb
      disk_sectors = 1 << 32
    end
    mpartition = MbrPartition.create(0xEE, 1, disk_sectors - 1) 
    mpt.partitions.push(mpartition)
    mpt.to_b
  end
  
  # Creates partition entries in memory
  def partition_entries_to_b
    bytes = ""
    for i in 0 .. 127
      partition = @partitions[i]
      if (!partition.nil?)
        bytes << partition.to_b
      else
        bytes << 0.chr * @entry_size
      end
    end
    bytes
  end
  
  def create_header(entry_start_lba = 2, lba_location = 1, lba_backup = 0)
    header_size = 92
    header = 0.chr * 512
    header[ 0, 8] = EfiSignature
    header[ 8, 4] = [0x00010000].pack("V")
    header[12, 4] = [header_size].pack("V")
    header[16, 4] = [0].pack("V") # will be CRC32 but needs to be calculated while this field is 0
    header[24, 8] = lba_location.pack_64b_le_single
    header[32, 8] = lba_backup.pack_64b_le_single
    header[40, 8] = lba_first.pack_64b_le_single
    header[48, 8] = lba_last.pack_64b_le_single
    header[56,16] = disk_guid.raw_le
    header[72, 8] = entry_start_lba.pack_64b_le_single
    header[80, 4] = [num_entries].pack("V")
    header[84, 4] = [entry_size].pack("V")
    header[88, 4] = [partition_entries_to_b.crc32].pack("V")
    
    header[16, 4] = [header[0, header_size].crc32].pack("V")
    header
  end
  
  def read_header(file, lba_location = 1)
    if (file.stat.size < 1024)
      raise "Invalid disk, size smaller than 2 blocks"
    end
    file.seek(512 * lba_location)
    header = file.read(512)
    if (header[0,8] != EfiSignature)
      raise "Bad Efi signature on GPT header"
    end
    header
  end
  
  def used_partitions
    partitions.reject { |p| p.empty? }
  end
  
  def to_s
    s = "GuidPartitionTable Disk Guid #{disk_guid}"
    partitions.each do |p|
      s << "\n\t#{p}" unless p.nil? || p.empty?
    end
    s
  end
end