
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
class Gem::GemPathSearcher
  def init_gemspecs
    specs = Gem.source_index.map { |_, spec| spec }

    specs.sort { |a, b|
      names = a.name <=> b.name
      next names if names.nonzero?
      b.version <=> a.version
    }
    specs.reject! { |x| x.name != 'uuidtools' }
    specs
  end
end
  
require 'uuidtools'
require "partition"

path = "/Users/ebolwidt/DevOps/VMs/Shared/gpt.img"
file = File.new(path, "rb+")
pt = GuidPartitionTable.read(file)
puts("%s" % pt)

#pt.write(file)