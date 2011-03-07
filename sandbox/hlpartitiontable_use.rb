$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'
require 'file/file_patch.rb'
require 'debootstrap/debootstrap.rb'

pt = PartitionTable.new
pt.type = "mbr"

proot = Partition.new(500000, Partition::Type_Linux_Data, "/", "ext2")
pboot = Partition.new(80000, Partition::Type_Linux_Data, "/boot", "ext2")
pt.partitions.push(proot, pboot)

# Add some more partitions to test MBR extended boot records
for i in 2 .. 10
  ptest = Partition.new(500, Partition::Type_Linux_Data, "/partition#{i}", "ext2")
  pt.partitions.push(ptest)
end


pt.create_image("tmp/highlevel.img")

#puts(pt)

pt.map_partitions_to_devices

puts("Partitions mapped to devices")

pt.newfs_partitions

puts("Partitions newfs-ed")

File.ensure_dir("tmp/mountpoint")
pt.mount("tmp/mountpoint")

bootstrap = Debootstrap.new
bootstrap.root_path = pt.mount_path
bootstrap.apt_cache_path = "tmp/apt-cache"
bootstrap.apt_lib_path = "tmp/apt-lib"

bootstrap.bind
bootstrap.bootstrap
bootstrap.apt_update
bootstrap.apt_dist_upgrade

exit 0

bootstrap.unbind

pt.unmount

pt.unmap_partitions_to_devices
