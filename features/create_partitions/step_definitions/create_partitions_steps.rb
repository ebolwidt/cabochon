# encoding: utf-8
require 'test/unit/assertions'
World(Test::Unit::Assertions)
require 'cucumber/formatter/unicode'
$:.unshift(File.dirname(__FILE__) + '/../../../lib')
require 'imgfile/imgfile'
require 'partition.rb'


Given /^an empty file (\S+) with size (\d+) sectors$/ do |path, size|
  @path = path
  @size = size
  
  File.create_empty(path, size.to_i * 512)
end

Given /^the following partitions to create:$/ do |table|
  @partitions = []
  # table is a Cucumber::Ast::Table
  table.hashes.each do |row|
    start_sector = row['start'].to_i
    end_sector = row['end'].to_i
    length_sectors = end_sector - start_sector + 1
    case row['kind']
      when 'primary'
        p = Partition.create(0x83, start_sector, length_sectors)
        @partitions.push(p)
      when 'extended'
        @extended = p = Partition.create(0x0f, start_sector, length_sectors)
        @partitions.push(p)
      when 'logical'
        p = Partition.create(0x83, start_sector, length_sectors)
        @extended.partitions.push(p)
    end    
  end
end

When /^I ask to create a fresh partition table$/ do
  partition_table = PartitionTable.new_table
  partition_table.partitions = @partitions
  File.open(@path, "rb+") do |f|
    partition_table.write(f)
  end
end

Then /^the list of partitions should be:$/ do |table|
  # table is a Cucumber::Ast::Table
  partition_table = nil
  File.open(@path, "rb+") do |f|
    partition_table = PartitionTable.read(f)
  end
  partitions = partition_table.partitions.select { |p| !p.nil? }
  if (!partition_table.extended.nil?)
    partitions.push(*partition_table.extended.partitions)
  end
  
  hashes = table.hashes
  assert_equal(hashes.length, partitions.length, "Number of partitions")
  for i in 0 .. hashes.length - 1
    row = hashes[i]
    partition = partitions[i]
    assert_equal(row['start'].to_i, partition.lba_start, "wrong lba_start for entry #{i}")
    assert_equal(row['end'].to_i, partition.lba_length + partition.lba_start - 1, "wrong lba_length for entry #{i}")
    case row['kind']
      when 'primary'
        assert_equal(0x83, partition.type, "incorrect partition type for primary for entry #{i}")
      when 'extended'
        assert_equal(0x0f, partition.type, "incorrect partition type for extended for entry #{i}")
      when 'logical'
        assert_equal(0x83, partition.type, "incorrect partition type for logical for entry #{i}")
        assert_not_nil(partition.parent, "not a logical partition for entry #{i}")
    end
  end

end
