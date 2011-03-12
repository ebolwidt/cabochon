require 'mount/mount.rb'
class Debootstrap
  
  attr_accessor :root_path
  attr_accessor :apt_cache_path, :apt_lib_path
  attr_accessor :url
  attr_accessor :suite
  
  def initialize
    @debootstrap_path = "/usr/sbin/debootstrap"
    @chroot_path = "/usr/sbin/chroot"
    @apt_get_path = "/usr/bin/apt-get"
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
    
    File.ensure_dir("#{root_path}/proc")
    File.ensure_dir("#{root_path}/dev")
    File.ensure_dir("#{root_path}/sys")
    Mount::mount("none", "#{root_path}/proc", "proc")
    Mount::bind("/dev", "#{root_path}/dev")
    Mount::bind("/sys", "#{root_path}/sys")
  end
  
  def bootstrap
    ensure_root_path
    output = KernelExt::fork_exec_get_output(@debootstrap_path, suite, root_path, url)
    puts(output)
  end
  
  def create_chroot_env
    {
      "DEBIAN_FRONTEND" => "noninteractive"
    }
  end
  
  def unbind
    ensure_root_path
    
    Mount::unmount("#{root_path}/proc")
    Mount::unmount("#{root_path}/dev")
    Mount::unmount("#{root_path}/sys")
    
    apt_cache_mounted_path = root_path + "/var/cache/apt"
    Mount::unbind(apt_cache_mounted_path)
    apt_lib_mounted_path = root_path + "/var/lib/apt"
    Mount::unbind(apt_lib_mounted_path)
  end
  
  # Runs non-interactive apt-get upgrade in chroot shell
  def apt_update
    output = KernelExt::fork_exec_get_output(create_chroot_env, @chroot_path, 
        root_path, @apt_get_path, "update", "-y")
    puts(output)
  end

  def apt_dist_upgrade
    output = KernelExt::fork_exec_get_output(create_chroot_env, @chroot_path, 
        root_path, @apt_get_path, "dist-upgrade", "-y")
    puts(output)
  end
  
  def apt_install(packages)
    packages.each do |package|
      output = KernelExt::fork_exec_get_output(create_chroot_env, @chroot_path, 
          root_path, @apt_get_path, "install", "-y", package)
      puts(output)
    end
  end
end
