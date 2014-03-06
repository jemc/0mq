
module ZMQ
  
  # The context object encapsulates all the global state associated
  # with the library. 
  class Context
    
    # The FFI pointer to the context.
    attr_reader :pointer
    
    def initialize
      @pointer = LibZMQ.zmq_ctx_new
    end
    
    # Destroy the ØMQ context.
    def terminate
      if @pointer
        rc = LibZMQ.version4?       ? 
          LibZMQ.zmq_ctx_term(@pointer) : 
          LibZMQ.zmq_term(@pointer)
        ZMQ.error_check true if rc == -1
        
        @pointer = nil
      end
    end
    
    # Create a Socket within this context.
    def socket(type, opts={})
      opts[:context] = self
      ZMQ::Socket.new type, opts
    end
    
    # Returns the context's FFI pointer.
    def to_ptr
      @pointer
    end
    
  end
  
  # The default context to be used if another context is not provided.
  DefaultContext = Context.new
  
end
