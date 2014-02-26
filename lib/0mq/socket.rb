
module ZMQ
  
  class Socket
    attr_reader :ptr
    attr_reader :context
    attr_reader :type
    
    def initialize(type, context:ZMQ::DefaultContext)
      @context = context
      @type = type
      @ptr = LibZMQ.zmq_socket @context.ptr, @type
      ZMQ.error_check true
    end
    
    # Get the socket type name as a symbol
    def type_sym
      ZMQ::SocketTypeNameMap[type].to_sym
    end
    
    # Set a socket option
    def set_opt(option, value)
      size = case value
      when String; value.size
      else; raise NotImplementedError
      end
      
      LibZMQ.zmq_setsockopt @ptr, option, value, size
      ZMQ.error_check true
    end
  end
  
end
