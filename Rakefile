
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

# RSpec tests
RSpec::Core::RakeTask.new :test

task :g  => :install
task :gp => :release

task :default => :test
