$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'test/unit'
require 'rubygems'
require 'partition'
require 'uuidtools'
require 'imgfile/imgfile'

class TestGuidPartitionTable < Test::Unit::TestCase
  LinuxWindowsDataGuid = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"
  LinuxSwapGuid = "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"
  AppleHfsHfsPlusGuid = "48465300-0000-11AA-AA11-00306543ECAC"
  
  Correct_disk_guid = "43B7D917-FBAB-45A5-BD3C-C68118C787A5"
  Correct_partitions =
  [
  [    63,   500, "myext4",     LinuxWindowsDataGuid, "41F65323-8371-4A45-B609-F071B694F0C0" ],
  [   504, 10000, "myswap",     LinuxSwapGuid,        "1DB8B717-A626-4D85-A0A4-2F3B6ECF5956" ],
  [ 10004, 11999, "myhfs",      AppleHfsHfsPlusGuid,  "657B28BA-229F-4965-A156-F546C1A2966A" ],
  [ 12000, 12999, "myfat32",    LinuxWindowsDataGuid, "24245B11-0014-43A3-820C-76D108130BD6" ],
  [ 13000, 13999, "myreiserfs", LinuxWindowsDataGuid, "E9E89D9A-01D3-4DC3-A5FF-A94C0A54DCB3" ]
  ]
  
  def verify_partitions(gpt)
    assert_equal(Correct_partitions.length, gpt.used_partitions.length)
    for i in 0 .. Correct_partitions.length-1
      correct = Correct_partitions[i]
      inspect = gpt.used_partitions[i]
      assert_equal(correct[0], inspect.lba_start)
      assert_equal(correct[1], inspect.lba_end)
      assert_equal(correct[2], inspect.name)
      assert_equal(correct[3], inspect.type_guid.to_s.upcase)
      assert_equal(correct[4], inspect.unique_guid.to_s.upcase)
    end
  end
  
  # This test reads a known partition table in a file and checks that the parsing of it is correct
  # The correct parsing was determined using both parted (which doesn't show guids) and gdisk which does.
  def test_known_layout(backup = false, path = "testdata/gpt.img")
    gpt = nil
    File.open(path, "rb") do |file|
      if (backup)
        gpt = GuidPartitionTable.read_backup(file)
      else
        gpt = GuidPartitionTable.read(file)
      end
    end
    
    assert_equal(Correct_disk_guid, gpt.disk_guid.to_s.upcase)
    verify_partitions(gpt)
  end
  
  def test_backup_known_layout
    test_known_layout(true)
  end
  
  # Tests the creation of a new GPT on an image by creating it and reading it back using the same partitions as the known layout
  def test_write_read
    gpt = GuidPartitionTable.new_table
    gpt.disk_guid = UUIDTools::UUID.parse(Correct_disk_guid) 
    for i in 0 .. Correct_partitions.length-1
      correct = Correct_partitions[i]
      p = GuidPartition.create(UUIDTools::UUID.parse(correct[3]), correct[0], correct[1], correct[2])
      p.unique_guid = UUIDTools::UUID.parse(correct[4])
      gpt.partitions.push(p)
    end
    
    path = "tmp/testgpt.img"
    File.create_empty(path, 15000 * 512)
    File.open(path, "rb+") do |file|
      gpt.write(file)
    end
    
    # Test primary GPT
    test_known_layout(false, path)
    # Test backup GPT
    test_known_layout(true, path)
  end
end