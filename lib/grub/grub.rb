require 'fileutils'

# Depends on the availability of Grub 2 (version 1.98 or higher)
# "Old" Grub is now called "legacy Grub" and "Grub 2" is "Grub"
module Grub
  # Copies files from source location, of the required architecture, to the /boot directory
  # in the image.
  def copy_grub_files(grubdir, architecture="i386-pc")
    FileUtils::cp_r("/usr/lib/grub/#{architecture}", grubdir)
  end
end