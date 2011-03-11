$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'hl-partition.rb'
require 'file/file_patch.rb'
require 'debootstrap/debootstrap.rb'
require 'grub/grub.rb'
require 'kernelext/kernelext'

KernelExt::debug = true

device = "/dev/mapper/loop0p1"

uuid = BlkId::blkid(device)

puts("UUID: #{uuid}")

Grub::install_grub(device, "tmp/mountpoint")

