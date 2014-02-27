
module ZMQ
  
  class Socket
    attr_reader :ptr
    attr_reader :context
    attr_reader :type
    
    def initialize(type, context:ZMQ::DefaultContext)
      @context = context
      @type = type
      @ptr = LibZMQ.zmq_socket @context.ptr, @type
      
      ObjectSpace.define_finalizer self,
                                   self.class.finalizer(@socket, Process.pid)
    end
    
    # Close the socket
    def close
      if @ptr
        ObjectSpace.undefine_finalizer self
        @temp_buffers.clear if @temp_buffers
        
        rc = LibZMQ.zmq_close @ptr
        ZMQ.error_check true if rc!=0
        
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
    def bind endpoint
      rc = LibZMQ.zmq_bind @ptr, endpoint
      ZMQ.error_check true if rc!=0
    end
    
    # Connect to an endpoint
    def connect endpoint
      rc = LibZMQ.zmq_connect @ptr, endpoint
      ZMQ.error_check true if rc!=0
    end
    
    # Unbind from an endpoint
    def unbind endpoint
      rc = LibZMQ.zmq_unbind @ptr, endpoint
      ZMQ.error_check true if rc!=0
    end
    
    # Disconnect to an endpoint
    def disconnect endpoint
      rc = LibZMQ.zmq_disconnect @ptr, endpoint
      ZMQ.error_check true if rc!=0
    end
    
    # Set a socket option
    def set_opt(option, value)
      type = @@option_types.fetch(option) \
        { raise ArgumentError, "Unknown option: #{option}" }
      
      unless type == :string
        valptr = FFI::MemoryPointer.new(type)
        valptr.send :"write_#{type}", value
        value = valptr
      end
      
      rc = LibZMQ.zmq_setsockopt @ptr, option, value, value.size
      ZMQ.error_check true if rc!=0
      
      value
    end
    
    # Get a socket option
    def get_opt(option)
      type = @@option_types.fetch(option) \
        { raise ArgumentError, "Unknown option: #{option}" }
      
      value, size = get_opt_pointers type
      
      rc = LibZMQ.zmq_getsockopt @ptr, option, value, size
      ZMQ.error_check true if rc!=0
      
      if type == :string
        value.read_string(size.read_int-1)
      else
        value.send :"read_#{type}"
      end
    end
    
  private
    
    def get_opt_pointers(type)
      @temp_buffers ||= { string: [
          FFI::MemoryPointer.new(255),
          FFI::MemoryPointer.new(:size_t).write_int(255)
      ] }
      @temp_buffers[type] ||= [
        FFI::MemoryPointer.new(type),
        FFI::MemoryPointer.new(:size_t).write_int(FFI.type_size(type))
      ]
    end
    
    @@option_types = {
    # Get options
      ZMQ::RCVMORE             => :int,
      ZMQ::RCVHWM              => :int,
      ZMQ::AFFINITY            => :uint64,
      ZMQ::IDENTITY            => :string,
      ZMQ::RATE                => :int,
      ZMQ::RECOVERY_IVL        => :int,
      ZMQ::SNDBUF              => :int,
      ZMQ::RCVBUF              => :int,
      ZMQ::LINGER              => :int,
      ZMQ::RECONNECT_IVL       => :int,
      ZMQ::RECONNECT_IVL_MAX   => :int,
      ZMQ::BACKLOG             => :int,
      ZMQ::MAXMSGSIZE          => :int64,
      ZMQ::MULTICAST_HOPS      => :int,
      ZMQ::RCVTIMEO            => :int,
      ZMQ::SNDTIMEO            => :int,
      ZMQ::IPV6                => :int,
      ZMQ::IPV4ONLY            => :int,
      ZMQ::IMMEDIATE           => :int,
      ZMQ::FD                  => :int,
      ZMQ::EVENTS              => :int,
      ZMQ::LAST_ENDPOINT       => :string,
      ZMQ::TCP_KEEPALIVE       => :int,
      ZMQ::TCP_KEEPALIVE_IDLE  => :int,
      ZMQ::TCP_KEEPALIVE_CNT   => :int,
      ZMQ::TCP_KEEPALIVE_INTVL => :int,
      ZMQ::MECHANISM           => :int,
      ZMQ::PLAIN_SERVER        => :int,
      ZMQ::PLAIN_USERNAME      => :string,
      ZMQ::PLAIN_PASSWORD      => :string,
      ZMQ::CURVE_PUBLICKEY     => :string,
      ZMQ::CURVE_SECRETKEY     => :string,
      ZMQ::CURVE_SERVERKEY     => :string,
      ZMQ::ZAP_DOMAIN          => :string,
    }.merge({
    # Set options
      ZMQ::SNDHWM              => :int,
      ZMQ::RCVHWM              => :int,
      ZMQ::AFFINITY            => :uint64,
      ZMQ::SUBSCRIBE           => :string,
      ZMQ::UNSUBSCRIBE         => :string,
      ZMQ::IDENTITY            => :string,
      ZMQ::RATE                => :int,
      ZMQ::RECOVERY_IVL        => :int,
      ZMQ::SNDBUF              => :int,
      ZMQ::RCVBUF              => :int,
      ZMQ::LINGER              => :int,
      ZMQ::RECONNECT_IVL       => :int,
      ZMQ::RECONNECT_IVL_MAX   => :int,
      ZMQ::RECONNECT_IVL       => :int,
      ZMQ::BACKLOG             => :int,
      ZMQ::MAXMSGSIZE          => :int64,
      ZMQ::MULTICAST_HOPS      => :int,
      ZMQ::RCVTIMEO            => :int,
      ZMQ::SNDTIMEO            => :int,
      ZMQ::IPV6                => :int,
      ZMQ::IPV4ONLY            => :int,
      ZMQ::IMMEDIATE           => :int,
      ZMQ::ROUTER_HANDOVER     => :int,
      ZMQ::ROUTER_MANDATORY    => :int,
      ZMQ::ROUTER_RAW          => :int,
      ZMQ::PROBE_ROUTER        => :int,
      ZMQ::XPUB_VERBOSE        => :int,
      ZMQ::REQ_CORRELATE       => :int,
      ZMQ::REQ_RELAXED         => :int,
      ZMQ::TCP_KEEPALIVE       => :int,
      ZMQ::TCP_KEEPALIVE_IDLE  => :int,
      ZMQ::TCP_KEEPALIVE_CNT   => :int,
      ZMQ::TCP_KEEPALIVE_INTVL => :int,
      ZMQ::TCP_ACCEPT_FILTER   => :string,
      ZMQ::PLAIN_SERVER        => :int,
      ZMQ::PLAIN_USERNAME      => :string,
      ZMQ::PLAIN_PASSWORD      => :string,
      ZMQ::CURVE_SERVER        => :int,
      ZMQ::CURVE_PUBLICKEY     => :string,
      ZMQ::CURVE_SECRETKEY     => :string,
      ZMQ::CURVE_SERVERKEY     => :string,
      ZMQ::ZAP_DOMAIN          => :string,
      ZMQ::CONFLATE            => :int,
    })
    
  end
  
end
