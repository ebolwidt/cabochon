$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'

pt = PartitionTable.new
pt.type = "mbr"

proot = Partition.new(1001, Partition::Type_Linux_Data, "/", "ext2")
pboot = Partition.new(511, Partition::Type_Linux_Data, "/boot", "ext2")
pt.partitions.push(proot, pboot)

# Add some more partitions to test MBR extended boot records
for i in 2 .. 10
  ptest = Partition.new(16, Partition::Type_Linux_Data, "/partition#{i}", "ext2")
  pt.partitions.push(ptest)
end


pt.create_image("tmp/highlevel.img")

puts(pt)
