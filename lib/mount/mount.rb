require "kernelext/kernelext.rb"

module Mount
  # TODO: determine if we are on MacOS in a better way
  @mkfs_linux_path = "/sbin/mkfs"
  @mount_path = [ "/sbin/mount", "/bin/mount" ]
  @unmount_path = [ "/sbin/umount", "/bin/umount" ]
  @macos_ext2_mount_path = "/usr/local/bin/fuse-ext2"
  
  def self.mount(device, mount_path)
    # TODO: cleanup code
    if (!File.exist? @mkfs_linux_path)
      KernelExt::fork_exec_get_output(@macos_ext2_mount_path, "-o", "rw+", device, mount_path)
    else
      KernelExt::fork_exec_get_output(@mount_path, device, mount_path)
    end
  end
  
  def self.unmount(mount_path)
    KernelExt::fork_exec_get_output(@unmount_path, mount_path)
  end
end