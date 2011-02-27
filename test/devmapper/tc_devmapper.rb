$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'test/unit'
require 'rubygems'
require 'devmapper/devmapper.rb'

class TestDevMapper < Test::Unit::TestCase
  # This integration test tries to invoke the DevMapper to map and then unmap a known partitioned image
  # This test merely tests whether the unix tools result in any errors
  # And if the known partitions were found
  def test_map_unmap
    path = "testdata/gpt.img"
    imagefile = File.new(path)
    mapping = DevMapper::map_partitions_to_devices(imagefile)
    DevMapper::unmap_partitions_to_devices(mapping)
    
    assert_equal(path, mapping.file)
    # 5 partitions in known image
    assert_equal(5, mapping.partition_devices.length)
  end
end