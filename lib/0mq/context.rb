
module ZMQ
  
  class Context
    attr_reader :ptr
    
    def initialize
      @ptr = LibZMQ.zmq_ctx_new
    end
  end
  
  DefaultContext = Context.new
  
end
