
module ZMQ
  
  class Proxy
    
    def initialize(frontend, backend, capture = nil)
      @frontend = frontend.nil? ? nil : frontend.to_ptr
      @backend  = backend.nil?  ? nil : backend.to_ptr
      @capture  = capture.nil?  ? nil : capture.to_ptr
    end
    
    # Block the current thread with the event loop of the proxy
    def run
      LibZMQ.zmq_proxy @frontend, @backend, @capture
    end
    
  end
  
end
