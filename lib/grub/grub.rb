require 'fileutils'
require 'erb'
# Depends on the availability of Grub 2 (version 1.98 or higher)
# "Old" Grub is now called "legacy Grub" and "Grub 2" is "Grub"
module Grub
  
  # TODO: determine kernel version dynamically
  def self.install_grub(root_device, root_mount_path, kernel="2.6.32-21")
    grub_dir = "#{root_mount_path}/boot/grub"
    copy_grub_files(grub_dir)
    File.open("#{grub_dir}/load.cfg", "w") { |file| file.write(create_load_cfg(root_device)) }
    File.open("#{grub_dir}/device.map", "w") { |file| file.write(create_device_map(root_device)) }
    File.open("#{grub_dir}/grub.cfg", "w") { |file| file.write(create_grub_cfg(root_device, kernel)) }
  end
  
  # Copies files from source location, of the required architecture, to the /boot directory
  # in the image.
  def self.copy_grub_files(grubdir, architecture="i386-pc")
    FileUtils::cp_r("/usr/lib/grub/#{architecture}", grubdir)
  end
  
  def self.create_load_cfg(root_device)
    uuid = BlkId::blkid(root_device)
    load_cfg = "search.fs_uuid #{uuid} root " 
    load_cfg << 'set prefix=($root)/boot/grub'
    load_cfg << 'set root=(hd0,1)'
    load_cfg
  end
  
  def self.create_device_map(root_device)
    "(hd0) #{root_device}"
  end
  
  def self.create_grub_cfg(root_device, kernel)
    uuid = BlkId::blkid(root_device)
    
    ERB.new <<-EOF
insmod ext2
set root='(/dev/sda,1)'
search --no-floppy --fs-uuid --set <%= uuid %>

linux   /boot/vmlinuz-<%= kernel %> root=UUID=<%= uuid %> ro quiet splash
initrd  /boot/initrd.img-<%= kernel %>

boot
    EOF
  end
end