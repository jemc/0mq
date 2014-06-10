      require 'pry'

module ZMQ
  
  # The context object encapsulates all the global state associated
  # with the library. 
  class Context
    
    # The FFI pointer to the context.
    attr_reader :pointer
    
    def initialize
      @pointer = LibZMQ.zmq_ctx_new
      
      ObjectSpace.define_finalizer self,
                                   self.class.finalizer(@pointer, Process.pid)
    end
    
    # Destroy the ØMQ context.
    def terminate
      if @pointer
        self.class.send :terminate_pointer, @pointer
        @pointer = nil
      end
    end
    
    # Create a safe finalizer for the context pointer to terminate on GC
    def self.finalizer(pointer, pid)
      Proc.new { terminate_pointer pointer if Process.pid == pid }
    end
    
    # Terminate the given FFI Context pointer
    def self.terminate_pointer(pointer)
      LibZMQ.respond_to?(:zmq_ctx_term) ? 
        LibZMQ.zmq_ctx_term(pointer)   : 
        LibZMQ.zmq_term(pointer)
    end
    private_class_method :terminate_pointer
    
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
