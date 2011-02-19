require 'iconv'
require 'uuidtools'
require 'partition/uuidtools_patch'

class GuidPartition
  attr_accessor :type_guid, :unique_guid, :lba_start, :lba_end, :attributes, :name, :length, :data
  
  def self.create(type_guid, lba_start, lba_end, name)
    p = GuidPartition.new
    p.type_guid, p.lba_start, p.lba_end, p.name = type_guid, lba_start, lba_end, name
    p.length = 128 # Default length
    # TODO: generate unique_guid
    p
  end
  
  def self.from_b(bytes)
    p = GuidPartition.new
    
    p.data = bytes
    p.length = bytes.length
    p.type_guid = UUIDTools::UUID.parse_raw_le(bytes[0, 16])
    p.unique_guid = UUIDTools::UUID.parse_raw_le(bytes[16, 16])
    p.lba_start = bytes[32,8].unpack("Q")[0]
    p.lba_end = bytes[40,8].unpack("Q")[0]
    p.attributes = bytes[48,8].unpack("Q")[0]
    p.name = bytes[56, 72]
    p.name = Iconv.iconv("UTF-8", "UTF-16LE", p.name).first
    p
  end

  def empty?
    type_guid.nil? || type_guid.nil_uuid?  
  end
  
  def to_b
    bytes = data
    if (bytes.nil?) 
      bytes = "\0" * length
    end
    
    bytes[0,16] = type_guid.raw
    bytes[16,16] = unique_guid.raw
    bytes[32,8] = [lba_start].pack("Q")
    bytes[40,8] = [lba_end].pack("Q")
    bytes[48,8] = [flags].pack("Q")
    bytes[56,72] = name.encode("binary")
    bytes
  end
  
  def to_s
    "GuidPartition Type #{@type_guid} unique #{@unique_guid} lba_start #{@lba_start} lba_end #{@lba_end} " +
    "attributes #{@attributes} name #{@name}"
  end
end

