require 'kernelext/kernelext.rb'
require 'file/file_patch.rb'
require 'blockdev/loop.rb'

module BlkId
  @blkid_path = "/sbin/blkid"
  
  def self.blkid(device)
    output = KernelExt::fork_exec_get_output(@blkid_path, "-o", "full", device)
    # /dev/mapper/loop0p1: UUID="be41817c-0231-43e8-87ab-d6f55ec5b7c5" TYPE="ext2"
    if (output.match(/\sUUID="(.*?)"\s/))
      $1
    else
      puts("No match for #{output}")
      nil  
    end
  end
end
