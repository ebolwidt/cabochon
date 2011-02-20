require 'test/unit'
$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'partition/chs.rb'

class TestCHS < Test::Unit::TestCase
  
  def test_two_way
    lba = 13925421
    chs = CHS.from_lba(lba)
    assert_equal(lba, chs.to_lba)
  end
  
  def test_simple
    chs = CHS.from_lba(63)
    assert_equal(0, chs.cylinder)
    assert_equal(1, chs.head)
    assert_equal(1, chs.sector)
  end
end


