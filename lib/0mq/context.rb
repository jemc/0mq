
module ZMQ
  
  # The context object encapsulates all the global state associated
  # with the library. 
  class Context
    
    # The FFI pointer to the context.
    attr_reader :pointer
    
    def initialize
      # FFI socket pointer for this context
      @pointer = LibZMQ.zmq_ctx_new
      
      # List of FFI socket pointers associated with this context.
      # Each Socket is responsible for registering and unregistering
      # its pointer from the Context it is associated with.
      # See #register_socket_pointer and #unregister_socket_pointer,
      # as well as #terminate and self.finalizer (where they get closed)
      @socket_pointers = Array.new
      @socket_pointers_mutex = Mutex.new
      
      ObjectSpace.define_finalizer self,
        self.class.finalizer(@pointer, @socket_pointers, Process.pid)
    end
    
    # @api private
    def register_socket_pointer pointer
      @socket_pointers_mutex.synchronize do
        @socket_pointers.push pointer
      end
    end
    
    # @api private
    def unregister_socket_pointer pointer
      @socket_pointers_mutex.synchronize do
        @socket_pointers.delete pointer
      end
    end
    
    # Destroy the ØMQ context.
    def terminate
      if @pointer
        ObjectSpace.undefine_finalizer self
        
        rc = LibZMQ.respond_to?(:zmq_ctx_term) ? 
          LibZMQ.zmq_ctx_term(pointer)   : 
          LibZMQ.zmq_term(pointer)
        ZMQ.error_check true if rc==-1
        
        @pointer = nil
      end
    end
    
    # Create a safe finalizer for the context pointer to terminate on GC
    def self.finalizer(pointer, socket_pointers, pid)
      Proc.new do
        if Process.pid == pid
          # Close all socket pointers associated with this context.
          #
          # If any of these sockets are still open when zmq_ctx_term is called,
          # the call will hang.  This is problematic, as the execution of
          # finalizers is not multithreaded, and the order of finalizers is not
          # guaranteed.  Even when the Sockets each hold a reference to the
          # Context, the Context could still be GCed first, causing lockup.
          socket_pointers.each { |ptr| LibZMQ.zmq_close ptr }
          socket_pointers.clear
          
          LibZMQ.respond_to?(:zmq_ctx_term) ? 
            LibZMQ.zmq_ctx_term(pointer)    : 
            LibZMQ.zmq_term(pointer)
        end
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
