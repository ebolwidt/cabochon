$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'devmapper/devmapper.rb'

imagefile = File.new("../testdata/gpt.img")
mapping = DevMapper::map_partitions_to_devices(imagefile)
DevMapper::unmap_partitions_to_devices(mapping)
puts(mapping)