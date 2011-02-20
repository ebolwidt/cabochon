require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'

task :default => [:test]

task :test => [:unit_test, :cucumber] 

task :unit_test do
  ruby "test/ts_all.rb"
end

Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = "features --format pretty"
end
