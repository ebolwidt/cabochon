# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'cucumber/formatter/unicode'
$:.unshift(File.dirname(__FILE__) + '/../../../lib')
require 'imgfile/imgfile'


Before do
end

After do
  if (!@path.nil?)
    File.delete(@path)
  end
end

Given /^that file (\S+) is removed if it existed$/ do |path|
  if (File.exists?(path))
    File.delete(path)
  end
end

When /^I ask to create a file (\S+) (with sparse disk usage)? and size (\d+)$/ do |path, sparse, size|
  @path = path
  File.create_empty(path, size.to_i, !sparse.nil?, true)
end

Then /^(?:it|the file) should exist$/ do
  File.exists?(@path).should be_true
end

Then /^it should have size (\d+)$/ do |size|
  File.stat(@path).size.should == size.to_i
end

def os_supports_sparse_files?  
  path = "tmp/test-file-sparse"
  begin
    File.open(path, "wb+") do |f|
      stat = File.stat(path)
      if (stat.blksize.nil?)
        return false
      end
      f.seek(stat.blksize)
      f.write("X")
    end
    stat = File.stat(path)
    return stat.blocks == 1
  ensure
    File.delete(path)  
  end
end

Then /^it should have disk usage (\d+) blocks?$/ do |blocks|
  stat = File.stat(@path) 
  if (os_supports_sparse_files?)
    stat.blocks.should == blocks.to_i
  else
    puts "WARNING: current OS does not support sparse files"
  end
end
