module Size
  def parse_bytes(s)
    if (s.match(/(\d+(?:\.\d*))(|b|s|k|kb|kib|m|mb|mib|g|gb|gib|t|tb|tib)/i))
      value = $1.to_f
      unit = $2.locase
      case unit
        # byte
        when '', 'b'
        bytes = value
        # sector
        when 's'
        bytes = value * 512
        # kibi
        when 'k','kib'
        bytes = value * 1024
        # kilo
        when 'kb'
        bytes = value * 1000
        # mibi
        when 'm', 'mib'
        bytes = value * 1024 * 1024
        # mega
        when 'mb'
        bytes = value * 1000 * 1000
        # gibi
        when 'g', 'gib'
        bytes = value * 1024 * 1024 * 1024
        # giga
        when 'gb'
        bytes = value * 1000 * 1000 * 1000
        # tebi
        when 't', 'tib'
        bytes = value * 1024 * 1024 * 1024 * 1024
        # tera
        when 'tb'
        bytes = value * 1000 * 1000 * 1000 * 1000
      end
      bytes
    end
  end
end