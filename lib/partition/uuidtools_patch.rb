require 'uuidtools'

class UUIDTools::UUID
  # Only the first three parts are byte-swapped
  def self.parse_raw_le(raw_string)
    clone = raw_string.clone
    clone[0,4] = clone[0,4].reverse
    clone[4,2] = clone[4,2].reverse
    clone[6,2] = clone[6,2].reverse
    return self.parse_raw(clone)
  end
end