require 'test/unit'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'partition/string_patch.rb'
require 'partition/integer_patch.rb'

class TestStringFixnum < Test::Unit::TestCase
  
  def test_pack_64b_le_single
    correct = [ 1, 0, 0, 0, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, 1.pack_64b_le_single)
    
    correct = [ 0, 1, 0, 0, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, 0x0100.pack_64b_le_single)
    
    correct = [ 0, 0, 1, 0, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, 0x010000.pack_64b_le_single)
    
    correct = [ 0, 0, 0, 1, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, 0x01000000.pack_64b_le_single)
    
    correct = [ 0, 0, 0, 0, 1, 0, 0, 0].pack("c*")
    assert_equal(correct, 0x0100000000.pack_64b_le_single)
    
    correct = [ 0, 0, 0, 0, 0, 1, 0, 0].pack("c*")
    assert_equal(correct, 0x010000000000.pack_64b_le_single)
    
    correct = [ 0, 0, 0, 0, 0, 0, 1, 0].pack("c*")
    assert_equal(correct, 0x01000000000000.pack_64b_le_single)
    
    correct = [ 0, 0, 0, 0, 0, 0, 0, 1].pack("c*")
    assert_equal(correct, 0x0100000000000000.pack_64b_le_single)
  end
  
  def test_unpack_64b_le_single
    correct = 0x01
    value   = [ 1, 0, 0, 0, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
    
    correct = 0x0100
    value   = [ 0, 1, 0, 0, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
    
    correct = 0x010000
    value   = [ 0, 0, 1, 0, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
    
    correct = 0x01000000
    value   = [ 0, 0, 0, 1, 0, 0, 0, 0].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
    
    correct = 0x0100000000
    value   = [ 0, 0, 0, 0, 1, 0, 0, 0].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
    
    correct = 0x010000000000
    value   = [ 0, 0, 0, 0, 0, 1, 0, 0].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
    
    correct = 0x01000000000000
    value   = [ 0, 0, 0, 0, 0, 0, 1, 0].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
    
    correct = 0x0100000000000000
    value   = [ 0, 0, 0, 0, 0, 0, 0, 1].pack("c*")
    assert_equal(correct, value.unpack_64b_le_single)
  end
  
  def test_random_pack_unpack
    0.upto(1000) do 
      value = rand(0xffffffffffffffff + 1)
      packed = value.pack_64b_le_single
      unpacked = packed.unpack_64b_le_single
      assert_equal(value, unpacked)
    end
  end
end