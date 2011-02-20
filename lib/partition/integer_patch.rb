class Integer
  def pack_64b_le_single
    result = ""
    for i in 0 .. 7
      result << ((self >> (8 * i)) & 0xff)
    end
    result
  end
end