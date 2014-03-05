
module ZMQ
  
  # A mechanism for applications to multiplex input/output events
  # in a level-triggered fashion over a set of sockets.
  class Poll
    
    # Construct a Poll object and start polling.
    # See #initialize for parameters.
    def self.poll(*sockets, &block)
      new(*sockets, &block).tap { |poll| poll.run }
    end
    
    # Accepts a list of sockets to poll for events
    # (ZMQ::POLLIN, ZMQ::POLLOUT, ZMQ::POLLERR).
    # Default is to poll for input (ZMQ::POLLIN).
    # To poll for a different kind of event, specify the socket
    # and event type as a key/value pair
    # (my_socket => ZMQ::POLLOUT).
    # Event flags can be binary OR'd together if necessary
    # (my_socket => ZMQ::POLLIN | ZMQ::POLLOUT).
    # 
    # Timeout can be specified in seconds as a keyword arg.
    # A value of 0 will return immediately (non-blocking), and
    # a value of -1 will block indefinitely until an event has
    # occurred. Fractions of a second are allowed.
    # Timeout defaults to block indefinitely (-1).
    #
    # Does not poll until #run is called.
    #
    # Example:
    # ZMQ::Poll.new socket1, socket2, socket3 => ZMQ::POLLOUT, timeout: 1
    def initialize(*sockets, &block)
      opts = sockets.last.is_a?(Hash) ? sockets.pop : {} # For Ruby 1.9
      
      @timeout = opts.fetch :timeout, -1
      
      # Package sockets into poll items.
      poll_items = sockets.map do |socket|
        LibZMQ::PollItem.new.tap { |pi|
          pi.socket = socket
          pi.events = ZMQ::POLLIN
        }
      end
      
      # Pull remaining sockets out of options hash and package into poll items.
      # Skip any option symbols in the hash; they aren't sockets.
      # Rejecting symbols allows duck-typed sockets to be included.
      opts.reject {|socket, events| socket.is_a? Symbol}.each do |socket, events|
        poll_items.push LibZMQ::PollItem.new.tap { |pi|
          pi.socket = socket
          pi.events = events
        }
      end
      
      # Convert seconds to miliseconds.
      timeout = (@timeout * 1000).to_i if @timeout > 0
      
      # Package PollItem array into a C array of pointers.
      poll_pointer_array = FFI::MemoryPointer.new FFI::Pointer, poll_items.count, true
      poll_pointer_array.write_array_of_pointer poll_items.map &:to_ptr
      
      # TODO: Delete this. Replaced by write_array_of_pointer
      # poll_items.count.times do |i|
      #   poll_pointer_array[i].write_pointer poll_items[i].to_ptr
      # end
      
      # Poll
      rc = LibZMQ::zmq_poll poll_pointer_array, poll_items.count, timeout
      # ZMQ.error_check true if rc==-1
      
      require 'pry'; binding.pry
    end
    
    # Start polling.
    def run
    end
    
  end
end


module LibZMQ
  class PollItem
    
    # Get the event flags:
    # ZMQ::POLLIN, ZMQ::POLLOUT, ZMQ::POLLERR.
    # Event flags are bitmasked.
    def events
      self[:events]
    end
    
    # Set the event flags:
    # ZMQ::POLLIN, ZMQ::POLLOUT, ZMQ::POLLERR.
    # Event flags are bitmasked.
    def events=(flags)
      self[:events] = flags
    end
    
    # Set the socket to poll for events on.
    # Accepts a ZMQ::Socket or a pointer.
    def socket=(sock)
      self[:socket] = sock.is_a?(FFI::Pointer) ? sock : sock.ptr
    end
    
  end
end
