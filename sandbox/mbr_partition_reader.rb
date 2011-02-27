$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'partition'

# path = "/Users/ebolwidt/DevOps/VMs/Shared/my.img"
path = "tmp/highlevel.img"
file = File.new(path, "rb+")
pt = MbrPartitionTable.read(file)
for p in pt.partitions
  puts("%s" % p)
end


#pt.write(file)