$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'

pt = PartitionTable.new

proot = Partition.new(1001, Partition::Type_Linux_Data, "/", "ext2")
pboot = Partition.new(511, Partition::Type_Linux_Data, "/boot", "ext2")

pt.partitions.push(proot, pboot)

pt.create_image("tmp/highlevel.img")

puts(pt)
