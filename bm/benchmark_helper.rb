
require 'benchmark'
require 'ruby-prof' unless defined? Rubinius

require_relative '../lib/0mq'

Thread.abort_on_exception = true


def benchmark description, opts={}, &block
  count   = opts.fetch :count,   1
  profile = opts.fetch :profile, false
  warmup  = opts.fetch :warmup,  false
  
  profile = false if defined? Rubinius
  
  block.call if warmup
  
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
