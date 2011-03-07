require "kernelext/kernelext.rb"

module Mount
  # TODO: determine if we are on MacOS in a better way
  @mkfs_linux_path = "/sbin/mkfs"
  @mount_path = [ "/sbin/mount", "/bin/mount" ]
  @unmount_path = [ "/sbin/umount", "/bin/umount" ]
  @macos_ext2_mount_path = "/usr/local/bin/fuse-ext2"
  
  # TODO: MacOS / Fuse doesn't support mounting a mount point inside a fuse mountpoint :-(
  
  def self.mount(device, mount_path, type=nil)
    # TODO: cleanup code
    if (!File.exist? @mkfs_linux_path)
      KernelExt::fork_exec_get_output(@macos_ext2_mount_path, "-o", "rb+", device, mount_path)
    else
      cmd = [@mount_path]
      if (!type.nil?)
        cmd.push("-t", type)
      end
      cmd.push(device, mount_path)
      KernelExt::fork_exec_get_output(*cmd)
    end
  end
  
  def self.unmount(mount_path)
    if (File.exist? mount_path)
      KernelExt::fork_exec_get_output(@unmount_path, mount_path)
    end
  end
  
  def self.bind(path, mount_path)
    # TODO: first check if this has already been bind mounted; it is possible to do this multiple times
    KernelExt::fork_exec_get_output(@mount_path, "--bind", path, mount_path)
  end
  
  def self.unbind(mount_path)
    if (File.directory? mount_path)
      KernelExt::fork_exec_get_output(@unmount_path, mount_path)
    end
  end
  
end