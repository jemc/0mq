
require_relative 'socket/options'

module ZMQ
  
  # See http://api.zeromq.org/4-0:zmq-socket
  # Not thread safe.
  class Socket
    
    # The FFI pointer to the socket.
    attr_reader :pointer
    # The socket's ZMQ::Context.
    attr_reader :context
    # The socket's ZeroMQ socket type (e.g. ZMQ::ROUTER).
    attr_reader :type
    
    def initialize(type, opts={})
      @closed = false
      @context = opts.fetch :context, ZMQ::DefaultContext
      @type = type
      @pointer = LibZMQ.zmq_socket @context.pointer, @type
      ZMQ.error_check true if @pointer.null?
      
      @msgptr = FFI::MemoryPointer.new LibZMQ::Message.size, 1, false
      
      @context.send :register_socket_pointer, @pointer
      
      ObjectSpace.define_finalizer self,
        self.class.finalizer(@pointer, @context, Process.pid)
      
      if block_given?
        yield self
        close
      end
    end
    
    # Show a useful inspect output
    def inspect
      "#<#{self.class}:#{type_sym}:#{object_id.to_s(16)}>"
    end
    
    # Close the socket
    def close
      @closed = true
      
      if @pointer
        @temp_buffers.clear if @temp_buffers
        
        ObjectSpace.undefine_finalizer self
        @context.send :unregister_socket_pointer, @pointer
        
        rc = LibZMQ.zmq_close @pointer
        ZMQ.error_check true if rc==-1
        
        @pointer = nil
        @context = nil
      end
    end
    
    # Returns true if the socket is closed.
    def closed?
      @closed
    end
    
    # Create a safe finalizer for the socket pointer to close on GC
    def self.finalizer(pointer, context, pid)
      Proc.new do
        if Process.pid == pid
          context.send :unregister_socket_pointer, pointer
          LibZMQ.zmq_close pointer
        end
      end
    end
    
    # Get the socket type name as a symbol
    def type_sym
      ZMQ::SocketTypeNameMap[type].to_sym
    end
    
    # Bind to an endpoint
    def bind(endpoint)
      rc = LibZMQ.zmq_bind @pointer, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Connect to an endpoint
    def connect(endpoint)
      rc = LibZMQ.zmq_connect @pointer, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Unbind from an endpoint
    def unbind(endpoint)
      rc = LibZMQ.zmq_unbind @pointer, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Disconnect from an endpoint
    def disconnect(endpoint)
      rc = LibZMQ.zmq_disconnect @pointer, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Send a string to the socket
    def send_string(string, flags = 0)
      string = string.to_s
      size = string.respond_to?(:bytesize) ? string.bytesize : string.size
      @msgbuf = LibC.malloc size
      @msgbuf.write_string string, size
      
      rc = LibZMQ.zmq_msg_init_data @msgptr, @msgbuf, size, LibC::Free, nil
      ZMQ.error_check true if rc==-1
      
      rc = LibZMQ.zmq_sendmsg @pointer, @msgptr, flags
      ZMQ.error_check true if rc==-1
      
      rc = LibZMQ.zmq_msg_close @msgptr
      ZMQ.error_check true if rc==-1
    end
    
    # Receive a string from the socket
    def recv_string(flags = 0)
      rc = LibZMQ.zmq_msg_init @msgptr
      ZMQ.error_check true if rc==-1
      
      rc = LibZMQ.zmq_recvmsg @pointer, @msgptr, flags
      ZMQ.error_check true if rc==-1
      
      str = LibZMQ.zmq_msg_data(@msgptr)
                  .read_string(LibZMQ.zmq_msg_size(@msgptr))
      
      rc = LibZMQ.zmq_msg_close @msgptr
      ZMQ.error_check true if rc==-1
      
      str
    end
    
    # Send a multipart message as an array of strings
    def send_array(array, flags = 0)
      array = array.to_a
      array[0...-1].each { |str| send_string str, ZMQ::SNDMORE|flags }
      send_string array.last, flags
    end
    
    # Receive a multipart message as an array of strings
    def recv_array(flags = 0)
      [].tap do |ary|
        loop do
          ary << recv_string(flags)
          break unless get_opt(ZMQ::RCVMORE)
        end
      end
    end
    
    # Send a multipart message as routing array and a body array
    # All parts before an empty part are considered routing parts,
    # and all parta after the empty part are considered body parts.
    # The empty delimiter part should not be included in the input arrays.
    def send_with_routing(routing, body)
      send_array [*routing, '', *body]
    end
    
    # Receive a multipart message as routing array and a body array
    # All parts before an empty part are considered routing parts,
    # and all parta after the empty part are considered body parts.
    # The empty delimiter part is not included in the resulting arrays.
    def recv_with_routing
      [[],[]].tap do |routing, body|
        loop do
          nxt = recv_string
          break if nxt.empty?
          routing << nxt
          raise ArgumentError, "Expected empty routing delimiter in "\
                               "multipart message: #{routing}" \
                                unless get_opt ZMQ::RCVMORE
        end
        loop do
          body << recv_string
          break unless get_opt(ZMQ::RCVMORE)
        end
      end
    end
    
    # Set a socket option
    def set_opt(option, value)
      type = @@option_types.fetch(option) \
        { raise ArgumentError, "Unknown option: #{option}" }
      
      unless type == :string
        if type == :bool
          valptr = FFI::MemoryPointer.new(:int)
          valptr.write_int(value ? 1 : 0)
        else
          valptr = FFI::MemoryPointer.new(type)
          valptr.send :"write_#{type}", value
        end
        value = valptr
      end
      
      rc = LibZMQ.zmq_setsockopt @pointer, option, value, value.size
      ZMQ.error_check true if rc==-1
      
      value
    end
    
    # Get a socket option
    def get_opt(option)
      type = @@option_types.fetch(option) \
        { raise ArgumentError, "Unknown option: #{option}" }
      
      value, size = get_opt_pointers type
      
      rc = LibZMQ.zmq_getsockopt @pointer, option, value, size
      ZMQ.error_check true if rc==-1
      
      if type == :string
        value.read_string(size.read_int-1)
      elsif type == :bool
        value.read_int == 1
      else
        value.send :"read_#{type}"
      end
    end
    
    # Returns the socket's FFI pointer.
    def to_ptr
      @pointer
    end
    
  private
    
    def get_opt_pointers(type)
      type = :int if type == :bool
      
      @temp_buffers ||= { string: [
          FFI::MemoryPointer.new(255),
          FFI::MemoryPointer.new(:size_t).write_int(255)
      ] }
      @temp_buffers[type] ||= [
        FFI::MemoryPointer.new(type),
        FFI::MemoryPointer.new(:size_t).write_int(FFI.type_size(type))
      ]
    end
    
  end
  
end
