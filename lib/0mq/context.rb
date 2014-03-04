
module ZMQ
  
  class Context
    attr_reader :ptr
    
    def initialize
      @ptr = LibZMQ.zmq_ctx_new
    end
    
    # Create a Socket within this context.
    def socket(type, opts={})
      opts[:context] = self
      ZMQ::Socket.new type, opts
    end
    
  end
  
  DefaultContext = Context.new
  
end
