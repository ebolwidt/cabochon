class CHS
  attr_accessor :cylinder, :head, :sector
  
  def self.from_lba(lba)
    if (lba >= 1023 * 255 * 63)
      return CHS.too_large
    end
    chs = CHS.new
    chs.cylinder = lba / (63*255)
    chs.head = (lba / 63) % 255
    chs.sector = (lba % 63) + 1
    chs
  end
  
  def self.too_large
    chs = CHS.new
    chs.cylinder = 1023
    chs.head = 254
    chs.sector = 63
    chs
  end
  
  def self.from_b(bytes)
    chs = CHS.new
    chs.cylinder = ((bytes[1] & 0xc0) << 2) | bytes[2]
    chs.head = bytes[0]
    chs.sector = bytes[1] & 0x3f
    chs
  end

  def to_lba
    cylinder * 63 * 255 + head * 63 + sector - 1
  end

  def to_b
    bytes = "\0" * 3
    bytes[0] = head
    bytes[1] = (sector & 0x3f) | ((cylinder >> 2) & 0xc0)
    bytes[2] = cylinder
    bytes
  end
  
  def to_s
    "Cylinder #{@cylinder} Head #{@head} Sector #{@sector}"
  end
end
