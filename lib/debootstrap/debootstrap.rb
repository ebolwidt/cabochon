require 'mount/mount.rb'
require 'partition/file_patch.rb'

class Debootstrap
  attr_accessor :root_path
  attr_accessor :apt_cache_path, :apt_lib_path
  attr_accessor :url
  attr_accessor :suite
  
  def initialize
    @debootstrap_path = "/usr/sbin/debootstrap"
    @suite = "lucid"
    @url = "http://archive.ubuntu.com/ubuntu"     
  end
  
  def ensure_root_path
    if (root_path.nil? || !File.directory?(root_path))
      raise "Root path '#{root_path}' doesn't exist"
    end
  end
  
  def bind
    ensure_root_path
    
    File.ensure_dir(apt_cache_path)
    apt_cache_mounted_path = root_path + "/var/cache/apt"
    File.ensure_dir(apt_cache_mounted_path)
    Mount::bind(apt_cache_path, apt_cache_mounted_path)
    
    File.ensure_dir(apt_lib_path)
    apt_lib_mounted_path = root_path + "/var/lib/apt"
    File.ensure_dir(apt_lib_mounted_path)
    Mount::bind(apt_lib_path, apt_lib_mounted_path)
  end
  
  def bootstrap
    ensure_root_path
    output = KernelExt::fork_exec_get_output(@debootstrap_path, suite, root_path, url)
    puts(output)
  end
  
  def unbind
    ensure_root_path
    apt_cache_mounted_path = root_path + "/var/cache/apt"
    Mount::unbind(apt_cache_mounted_path)
    apt_lib_mounted_path = root_path + "/var/lib/apt"
    Mount::unbind(apt_lib_mounted_path)
  end
end