require 'iconv'
require 'uuidtools'

class GuidPartition
  attr_accessor :type_guid, :unique_guid, :lba_start, :lba_end, :attributes, :name, :length, :data
  
  def self.create(type_guid, lba_start, lba_end, name)
    p = GuidPartition.new
    p.type_guid, p.lba_start, p.lba_end, p.name = type_guid, lba_start, lba_end, name
    p.length = 128 # Default length
    p.unique_guid = UUIDTools::UUID.random_create
    p.attributes = 0
    p
  end
  
  def self.from_b(bytes)
    p = GuidPartition.new
    
    p.data = bytes
    p.length = bytes.length
    p.type_guid = UUIDTools::UUID.parse_raw_le(bytes[0, 16])
    p.unique_guid = UUIDTools::UUID.parse_raw_le(bytes[16, 16])
    p.lba_start = bytes[32,8].unpack_64b_le_single
    p.lba_end = bytes[40,8].unpack_64b_le_single
    p.attributes = bytes[48,8].unpack_64b_le_single
    p.name = GuidPartition.decode_name(bytes[56, 72])
    p
  end

  def self.decode_name(bytes)
    (bytes.length / 2 - 1).downto(0) do |i|
      if (bytes[i*2] != 0 || bytes[i*2+1] != 0)
        bytes = bytes[0, i * 2 + 2]
        break
      end
    end
    
    Iconv.iconv("UTF-8", "UTF-16LE", bytes).first
  end
  
  def self.encode_name(name, length)
    bytes = Iconv.iconv("UTF-16LE", "UTF-8", name).first  
  
    bytes << 0.chr * (length - bytes.length)
    bytes
  end
  
  def empty?
    type_guid.nil? || type_guid.nil_uuid?
  end
  
  def to_b
    bytes = data
    if (bytes.nil?) 
      bytes = "\0" * length
    end
    
    bytes[0,16] = type_guid.raw_le
    bytes[16,16] = unique_guid.raw_le
    bytes[32,8] = lba_start.pack_64b_le_single
    bytes[40,8] = lba_end.pack_64b_le_single
    bytes[48,8] = attributes.pack_64b_le_single
    bytes[56,72] = GuidPartition.encode_name(name, 72)
    bytes
  end
  
  def to_s
    "GuidPartition Type #{@type_guid} unique #{@unique_guid} lba_start #{@lba_start} lba_end #{@lba_end} " +
    "attributes #{@attributes} name #{@name}"
  end
end

