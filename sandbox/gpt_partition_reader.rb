
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
  
require 'uuidtools'
require 'partition'

path = "/Users/ebolwidt/DevOps/VMs/Shared/gpt.img"
file = File.new(path, "rb+")
pt = GuidPartitionTable.read(file)
puts("%s" % pt)

#pt.write(file)