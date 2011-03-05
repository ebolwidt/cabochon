require 'kernelext/kernelext.rb'
require 'file/file_patch.rb'

module Loop
  @losetup_path = "/sbin/losetup"
  
  # Sets up loop device for file at path, returns the name of the loop device that was created
  def self.add(path, read_only = false, offset = nil, size = nil)
    path = path.path if (path.is_a? File)
    path = File.expand_path(path)
    args = [@losetup_path, "--show"]
    if (read_only)
      args.push("--read-only")
    end
    if (!offset.nil?)
      args.push("--offset", offset)
    end
    if (!size.nil?)
      args.push("--sizelimit", size)
    end
    args.push("-f", path)
    line = KernelExt::fork_exec_get_output(*args)
    line.strip
  end
  
  # Removes loop device
  def self.remove(device)
    KernelExt::fork_exec_get_output(@losetup_path, "-d", device)
  end
  
  # Removes all loop devices associated with given file
  def self.remove_for(path)
    devices = devices_for(path)
    devices.each { |device| remove(device) }
  end
  
  def self.file_name_for(loop_dev)
    File.open(loop_dev, "rb") do |f|
      v = "\0" * 224            # space for struct loop_info
      f.ioctl(0x4C05, v)        # LOOP_GET_STATUS64
      v[56,64].unpack("A64")[0] # lo_file_name
    end
  end
  
  def self.devices
    devices = []
    File.open("/proc/partitions", "rb") do |f|
      lines = f.readlines
      lines.slice!(0,2)
      lines.each do |line|
        if (line.match(/^\s+\d+\s+\d+\s+\d+\s+(loop.*?)$/))
          devices.push("/dev/#{$1}")
        end
      end
    end
    devices
  end
  
  def self.device_for(path)
    loop_devs = devices_for(path)
    if (loop_devs.length == 0)
      nil
    else
      loop_devs[0]
    end
  end
  
  def self.devices_for(path)
    path = path.path if (path.is_a? File)
    path = File.expand_path(path)
    loop_devs = devices
    loop_devs.reject! { |dev| file_name_for(dev) != path }
    loop_devs
  end
end
