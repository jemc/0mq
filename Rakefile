
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

task :default => :test

# RSpec tests
RSpec::Core::RakeTask.new :test

task :g  => :install
task :gp => :release

task :profile do
  require_relative "bm/send_receive"
end
