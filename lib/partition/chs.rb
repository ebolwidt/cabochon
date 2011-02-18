class CHS
  attr_accessor :cylinder, :head, :sector
  
  def initialize(bytes=nil)
    if (bytes.nil?)
      @cylinder = 1023
      @head = 254
      @sector = 63
    else
      @cylinder = ((bytes[1] & 0xc0) << 2) | bytes[2]
      @head = bytes[0]
      @sector = bytes[1] & 0x3f
    end
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
