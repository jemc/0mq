
module ZMQ
  
  class Socket
    attr_reader :ptr
    attr_reader :context
    attr_reader :type
    
    def initialize(type, context:ZMQ::DefaultContext)
      @context = context
      @type = type
      @ptr = LibZMQ.zmq_socket @context.ptr, @type
      
      @msgptr = FFI::MemoryPointer.new LibZMQ::Message.size, 1, false
      
      ObjectSpace.define_finalizer self,
                                   self.class.finalizer(@socket, Process.pid)
    end
    
    # Close the socket
    def close
      if @ptr
        ObjectSpace.undefine_finalizer self
        @temp_buffers.clear if @temp_buffers
        
        rc = LibZMQ.zmq_close @ptr
        ZMQ.error_check true if rc==-1
        
        @ptr = nil
      end
    end
    
    # Create a safe finalizer for the socket ptr to close on GC of the object
    def self.finalizer(ptr, pid)
      Proc.new { LibZMQ.zmq_close ptr if Process.pid == pid }
    end
    
    # Get the socket type name as a symbol
    def type_sym
      ZMQ::SocketTypeNameMap[type].to_sym
    end
    
    # Bind to an endpoint
    def bind(endpoint)
      rc = LibZMQ.zmq_bind @ptr, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Connect to an endpoint
    def connect(endpoint)
      rc = LibZMQ.zmq_connect @ptr, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Unbind from an endpoint
    def unbind(endpoint)
      rc = LibZMQ.zmq_unbind @ptr, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Disconnect to an endpoint
    def disconnect(endpoint)
      rc = LibZMQ.zmq_disconnect @ptr, endpoint
      ZMQ.error_check true if rc==-1
    end
    
    # Send a string to the socket
    def send_string(string, flags = 0)
      size = string.respond_to?(:bytesize) ? string.bytesize : string.size
      @msgbuf = LibC.malloc size
      @msgbuf.write_string string, size
      
      rc = LibZMQ.zmq_msg_init_data @msgptr, @msgbuf, size, LibC::Free, nil
      ZMQ.error_check true if rc==-1
      
      rc = LibZMQ.zmq_sendmsg @ptr, @msgptr, flags
      ZMQ.error_check true if rc==-1
      
      rc = LibZMQ.zmq_msg_close @msgptr
      ZMQ.error_check true if rc==-1
    end
    
    # Receive a string from the socket
    def recv_string(flags = 0)
      rc = LibZMQ.zmq_msg_init @msgptr
      ZMQ.error_check true if rc==-1
      
      rc = LibZMQ.zmq_recvmsg @ptr, @msgptr, flags
      ZMQ.error_check true if rc==-1
      
      str = LibZMQ.zmq_msg_data(@msgptr)
                  .read_string(LibZMQ.zmq_msg_size(@msgptr))
      
      rc = LibZMQ.zmq_msg_close @msgptr
      ZMQ.error_check true if rc==-1
      
      str
    end
    
    # Send a multipart message as an array of strings
    def send_array(ary)
      last = ary.last
      
      ary[0...-1].each { |str| send_string str, ZMQ::SNDMORE }
      send_string last
    end
    
    # Receive a multipart message as an array of strings
    def recv_array
      [].tap do |ary|
        loop do
          ary << recv_string
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
      
      rc = LibZMQ.zmq_setsockopt @ptr, option, value, value.size
      ZMQ.error_check true if rc==-1
      
      value
    end
    
    # Get a socket option
    def get_opt(option)
      type = @@option_types.fetch(option) \
        { raise ArgumentError, "Unknown option: #{option}" }
      
      value, size = get_opt_pointers type
      
      rc = LibZMQ.zmq_getsockopt @ptr, option, value, size
      ZMQ.error_check true if rc==-1
      
      if type == :string
        value.read_string(size.read_int-1)
      elsif type == :bool
        value.read_int == 1
      else
        value.send :"read_#{type}"
      end
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
    
    @@get_options = {
      :RCVMORE             => :bool,
      :RCVHWM              => :int,
      :AFFINITY            => :uint64,
      :IDENTITY            => :string,
      :RATE                => :int,
      :RECOVERY_IVL        => :int,
      :SNDBUF              => :int,
      :RCVBUF              => :int,
      :LINGER              => :int,
      :RECONNECT_IVL       => :int,
      :RECONNECT_IVL_MAX   => :int,
      :BACKLOG             => :int,
      :MAXMSGSIZE          => :int64,
      :MULTICAST_HOPS      => :int,
      :RCVTIMEO            => :int,
      :SNDTIMEO            => :int,
      :IPV6                => :bool,
      :IPV4ONLY            => :bool,
      :IMMEDIATE           => :bool,
      :FD                  => :int,
      :EVENTS              => :int,
      :LAST_ENDPOINT       => :string,
      :TCP_KEEPALIVE       => :int,
      :TCP_KEEPALIVE_IDLE  => :int,
      :TCP_KEEPALIVE_CNT   => :int,
      :TCP_KEEPALIVE_INTVL => :int,
      :MECHANISM           => :int,
      :PLAIN_SERVER        => :int,
      :PLAIN_USERNAME      => :string,
      :PLAIN_PASSWORD      => :string,
      :CURVE_PUBLICKEY     => :string,
      :CURVE_SECRETKEY     => :string,
      :CURVE_SERVERKEY     => :string,
      :ZAP_DOMAIN          => :string,
    }
    
    @@set_options = {
      :SNDHWM              => :int,
      :RCVHWM              => :int,
      :AFFINITY            => :uint64,
      :SUBSCRIBE           => :string,
      :UNSUBSCRIBE         => :string,
      :IDENTITY            => :string,
      :RATE                => :int,
      :RECOVERY_IVL        => :int,
      :SNDBUF              => :int,
      :RCVBUF              => :int,
      :LINGER              => :int,
      :RECONNECT_IVL       => :int,
      :RECONNECT_IVL_MAX   => :int,
      :RECONNECT_IVL       => :int,
      :BACKLOG             => :int,
      :MAXMSGSIZE          => :int64,
      :MULTICAST_HOPS      => :int,
      :RCVTIMEO            => :int,
      :SNDTIMEO            => :int,
      :IPV6                => :bool,
      :IPV4ONLY            => :bool,
      :IMMEDIATE           => :bool,
      :ROUTER_HANDOVER     => :int,
      :ROUTER_MANDATORY    => :int,
      :ROUTER_RAW          => :int,
      :PROBE_ROUTER        => :int,
      :XPUB_VERBOSE        => :int,
      :REQ_CORRELATE       => :int,
      :REQ_RELAXED         => :int,
      :TCP_KEEPALIVE       => :int,
      :TCP_KEEPALIVE_IDLE  => :int,
      :TCP_KEEPALIVE_CNT   => :int,
      :TCP_KEEPALIVE_INTVL => :int,
      :TCP_ACCEPT_FILTER   => :string,
      :PLAIN_SERVER        => :int,
      :PLAIN_USERNAME      => :string,
      :PLAIN_PASSWORD      => :string,
      :CURVE_SERVER        => :int,
      :CURVE_PUBLICKEY     => :string,
      :CURVE_SECRETKEY     => :string,
      :CURVE_SERVERKEY     => :string,
      :ZAP_DOMAIN          => :string,
      :CONFLATE            => :bool,
    }
    
    # Set up map of option codes to option types
    @@option_types = {}
    @@get_options.each_pair { |n,t| @@option_types[ZMQ.const_get(n)] = t }
    @@set_options.each_pair { |n,t| @@option_types[ZMQ.const_get(n)] = t }
    
    p @@set_options.keys - @@get_options.keys
    
  public
    
    # Define the socket option reader methods
    @@get_options.keys.each do |name|
      code = ZMQ.const_get(name)
      # Get the given socket option
      define_method(name.downcase) { get_opt code }
    end
    
    # Define the socket option writer methods
    @@set_options.keys.each do |name|
      code = ZMQ.const_get(name)
      name = :"#{name}=" unless [:SUBSCRIBE, :UNSUBSCRIBE].include? name
      # Set the given socket option
      define_method(name.downcase) { |val| set_opt code, val }
    end
    
  end
  
end
