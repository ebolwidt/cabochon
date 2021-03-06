require "kernelext/kernelext.rb"

module NewFs
  @mkfs_linux_path = "/sbin/mkfs"
  @newfs_macos_ext2_path = "/usr/local/bin/fuse-ext2.mke2fs"
  @newfs_macos_newfs_generic_path = "/sbin/newfs_"
  
  def self.newfs(device, type)
    if (File.exist? @mkfs_linux_path)
      newfs_linux(device, type)
    else
      newfs_macos(device, type)
    end
  end
  
  def self.newfs_linux(device, type)
    KernelExt::fork_exec_get_output(@mkfs_linux_path, "-t", type, device)  
  end
  
  def self.newfs_macos(device, type)
    case type
      when 'ext2' then
      KernelExt::fork_exec_get_output(@newfs_macos_ext2_path, device)
    else
      if (File.exist? @newfs_macos_newfs_generic_path + type)
        KernelExt::fork_exec_get_output(@newfs_macos_newfs_generic_path + type, device)
      end
    end
  end

end