$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'
require 'file/file_patch.rb'
require 'debootstrap/debootstrap.rb'
require 'grub/grub.rb'

pt = PartitionTable.new
pt.type = "mbr"
#pt.type = "gpt"

proot = Partition.new(1000000, Partition::Type_Linux_Data, "/", "ext2")
pt.partitions.push(proot)

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

bootstrap.apt_install(["linux-headers-generic", "linux-restricted-modules-generic", "linux-restricted-modules-generic", "linux-image-generic" ])

root = pt.root_partition
Grub::install_grub(pt.device, root.device, root.mount_path)

exit 0

bootstrap.unbind

pt.unmount

pt.unmap_partitions_to_devices
