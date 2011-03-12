require 'fileutils'
require 'erb'
require 'blockdev/blkid'
require 'kernelext/kernelext.rb'

# Depends on the availability of Grub 2 (version 1.98 or higher)
# "Old" Grub is now called "legacy Grub" and "Grub 2" is "Grub"
module Grub
  @grub_mkimage_path = "/usr/bin/grub-mkimage"
  @grub_setup_path = "/usr/bin/grub-setup"
  
  
  # TODO: determine kernel version dynamically
  def self.install_grub(root_device, root_mount_path, kernel="2.6.32-21")
    grub_dir = "#{root_mount_path}/boot/grub"
    copy_grub_files(grub_dir)
    File.open("#{grub_dir}/load.cfg", "w") { |file| file.write(create_load_cfg(root_device)) }
    File.open("#{grub_dir}/device.map", "w") { |file| file.write(create_device_map(root_device)) }
    File.open("#{grub_dir}/grub.cfg", "w") { |file| file.write(create_grub_cfg(root_device, kernel)) }
    mkimage(grub_dir)
    setup(grub_dir)
  end
  
  #$GRUBTOOLS/bin/grub-mkimage -c $GRUBDIR/load.cfg --output=$GRUBDIR/core.img --prefix=/boot/grub biosdisk ext2 part_msdos search_fs_uuid
  def self.mkimage(grub_dir)
    # TODO: include only those modules that are actually needed (file system of root/boot partition, and msdos OR gpt)
    output = KernelExt::fork_exec_get_output(@grub_mkimage_path, "-c", "#{grub_dir}/load.cfg", "--output", "#{grub_dir}/core.img", "--prefix", "/boot/grub", 
             "ext2", "part_msdos", "part_gpt", "search_fs_uuid")
    puts(output)
  end
  
  # $GRUBTOOLS/sbin/grub-setup -b boot.img -c core.img -r "(hd0,1)" --directory=$GRUBDIR --device-map=$GRUBDIR/device.map "(hd0)"
  def self.setup(grub_dir)
    output = KernelExt::fork_exec_get_output(@grub_setup_path, "-b", "boot.img", "-c", "core.img", "-r", "(hd0,1)", "--directory", grub_dir, "--device-map", "#{grub_dir}/device.map", "(hd0)")
    puts(output)
  end
  
  # Copies files from source location, of the required architecture, to the /boot directory
  # in the image.
  def self.copy_grub_files(grub_dir, architecture="i386-pc")
    FileUtils::cp_r("/usr/lib/grub/#{architecture}", grub_dir)
  end
  
  def self.create_load_cfg(root_device)
    uuid = BlkId::blkid(root_device)
    load_cfg = "search.fs_uuid #{uuid} root " 
    load_cfg << 'set prefix=($root)/boot/grub'
    load_cfg << 'set root=(hd0,1)'
    load_cfg << "\n"
    load_cfg
  end
  
  def self.create_device_map(root_device)
    "(hd0) #{root_device}\n"
  end
  
  def self.create_grub_cfg(root_device, kernel)
    uuid = BlkId::blkid(root_device)
    
    erb = ERB.new <<-EOF
insmod ext2
set root='(/dev/sda,1)'
search --no-floppy --fs-uuid --set <%= uuid %>

linux   /boot/vmlinuz-<%= kernel %> root=UUID=<%= uuid %> ro quiet splash
initrd  /boot/initrd.img-<%= kernel %>

boot
    EOF
    erb.result(binding)
  end
  
  
end
