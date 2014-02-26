
module ZMQ
  
  class Socket
    attr_reader :ptr
    attr_reader :context
    
    def initialize(type, context:ZMQ::DefaultContext)
      @context = context
      @ptr = LibZMQ.zmq_socket @context.ptr, type
    end
  end
  
  DefaultContext = Context.new
  
end
