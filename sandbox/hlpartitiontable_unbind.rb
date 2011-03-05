$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'
require 'file/file_patch.rb'
require 'debootstrap/debootstrap.rb'

pt = PartitionTable.new
pt.type = "mbr"

proot = Partition.new(100000, Partition::Type_Linux_Data, "/", "ext2")
pboot = Partition.new(50000, Partition::Type_Linux_Data, "/boot", "ext2")
pt.partitions.push(proot, pboot)

# Add some more partitions to test MBR extended boot records
for i in 2 .. 10
  ptest = Partition.new(500, Partition::Type_Linux_Data, "/partition#{i}", "ext2")
  pt.partitions.push(ptest)
end


pt.create_image("tmp/highlevel.img")

pt.dry_mount("tmp/mountpoint")

bootstrap = Debootstrap.new
bootstrap.root_path = pt.mount_path
bootstrap.apt_cache_path = "tmp/apt-cache"
bootstrap.apt_lib_path = "tmp/apt-lib"

bootstrap.unbind

pt.unmount
pt.unmap_partitions_to_devices