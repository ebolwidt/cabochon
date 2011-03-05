$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'
require 'file/file_patch.rb'
require 'debootstrap/debootstrap.rb'

KernelExt::debug = true

path = "tmp/highlevel.img"
#path = "/home/vmplanet/cabochon/tmp/highlevel.img"
mount_point = "tmp/mountpoint"

bootstrap = Debootstrap.new
bootstrap.root_path = mount_point
bootstrap.apt_cache_path = "tmp/apt-cache"
bootstrap.apt_lib_path = "tmp/apt-lib"

bootstrap.unbind

DevMapper.unmount_partitions(path)
DevMapper.unmap_partitions_to_devices(path)
