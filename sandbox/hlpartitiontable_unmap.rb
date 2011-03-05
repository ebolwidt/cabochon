$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'
require 'file/file_patch.rb'
require 'debootstrap/debootstrap.rb'

#path = "tmp/highlevel.img"
path = "/home/vmplanet/cabochon/tmp/highlevel.img"

DevMapper.unmap_partitions_to_devices(path)
