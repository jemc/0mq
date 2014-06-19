
require 'benchmark'
require 'ruby-prof'

require_relative '../lib/0mq'


def benchmark description, count:1, profile:false, &block
  description = "#{description} #{count} times" if count > 1
  puts
  puts description
  
  RubyProf.start if profile
  
  start_time = Time.now
  
  count.times &block
  
  end_time = Time.now
  
  RubyProf::FlatPrinter.new(RubyProf.stop).print(STDOUT) if profile
  
  puts if profile
  puts description if profile
  puts "completed in #{Time.now - start_time} seconds"\
       " #{profile ? "(with profiling)" : ""}"
end
