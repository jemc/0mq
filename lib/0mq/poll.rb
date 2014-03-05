
module ZMQ
  
  # A mechanism for applications to multiplex input/output events
  # in a level-triggered fashion over a set of sockets.
  class Poll
    # Timeout is specified in seconds.
    # A value of 0 will return immediately (non-blocking), and
    # a value of -1 will block indefinitely until an event has
    # occurred. Fractions of a second are allowed.
    # Timeout defaults to block indefinitely (-1).
    attr_accessor :timeout
    
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
    # See the :timeout accessor.
    #
    # Does not poll until #run is called.
    #
    # Example:
    # ZMQ::Poll.new socket1, socket2, socket3 => ZMQ::POLLOUT, timeout: 1
    def initialize(*sockets, &block)
      opts = sockets.last.is_a?(Hash) ? sockets.pop : {} # For Ruby 1.9
      
      @timeout = opts.fetch :timeout, -1
      
      poll_items = []
      socks = {}
      
      sockets.each { |socket| socks[socket] = ZMQ::POLLIN }
      
      # Pull remaining sockets out of options hash and package into poll items.
      # Skip any option symbols in the hash; they aren't sockets.
      # Rejecting symbols allows duck-typed sockets to be included.
      socks.merge! opts.reject {|socket, events| socket.is_a? Symbol}
      
      # Build table to reference ZMQ::Socket to its pointer's address.
      # This is an easy way to reconnect PollItem to ZMQ::Socket without
      # having to store multiple dimensions in the socks hash.
      socket_lookup = {}
      socks.each { |socket, event| socket_lookup[socket.ptr.address] = socket }
      
      # Allocate space for C PollItem (zmq_pollitem_t) structs.
      poll_pointer_array = FFI::MemoryPointer.new LibZMQ::PollItem, socks.count, true
      
      # Create the PollItem objects.
      # Initializing them within the FFI::MemoryPointer prevents having to copy
      # the struct data to the MemoryPointer when polling, then back again to
      # retrieve the revents flags.
      i = 0
      socks.each do |socket, events|
        poll_items.push LibZMQ::PollItem.new(poll_pointer_array[i]).tap { |pi|
          pi.socket = socket
          pi.events = events
        }
        
        i += 1
      end
      
      # Convert seconds to miliseconds.
      timeout = (@timeout * 1000).to_i if @timeout > 0
      
      # Poll
      rc = LibZMQ::zmq_poll poll_pointer_array, poll_items.count, timeout
      ZMQ.error_check true if rc==-1
      
      # Create a hash of the items with triggered events.
      # (ZMQ::Socket => revents)
      triggered_items = poll_items.select { |pi| pi.revents > 0 }
        .map { |pi| [socket_lookup[pi.socket.address], pi.revents] }
        .to_h
      
      # Pass triggered sockets to block.
      triggered_items.each { |socket, revents| block.call socket, revents }
      
      triggered_items
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
    
    # Get requested events that triggered:
    # ZMQ::POLLIN, ZMQ::POLLOUT, ZMQ::POLLERR.
    # Event flags are bitmasked.
    def revents
      self[:revents]
    end
    
    # Set the socket to poll for events on.
    # Accepts a ZMQ::Socket or a pointer.
    def socket=(sock)
      self[:socket] = sock.is_a?(FFI::Pointer) ? sock : sock.ptr
    end
    
  end
end
