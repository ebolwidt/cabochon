class String
  def unpack_64b_le_single
    result = 0
    for i in 0 .. 7
      result |= self[i] << (8 * i)
    end
    result
  end
  
  def crc32
    n = length
    r = 0xFFFFFFFF
    n.times do |i|
      r ^= self[i]
      8.times do
        if (r & 1)!=0
          r = (r>>1) ^ 0xEDB88320
        else
          r >>= 1
        end
      end
    end
    r ^ 0xFFFFFFFF
  end
  
end
