require 'test/unit'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'partition/chs.rb'

class TestCHS < Test::Unit::TestCase
  
  def test_two_way
    lba = 13925421
    chs = CHS.from_lba(lba)
    assert_equal(lba, chs.to_lba)
  end
  
  def test_simple
    puts(CHS.from_lba(64))
  end
end


