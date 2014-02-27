
module ZMQ
  
  class Proxy
    
    def initialize(frontend, backend, capture = nil)
      @frontend = frontend.nil? ? nil : frontend.ptr
      @backend  = backend.nil?  ? nil : backend.ptr
      @capture  = capture.nil?  ? nil : capture.ptr
    end
    
    # Block the current thread with the event loop of the proxy
    def run
      LibZMQ.zmq_proxy @frontend, @backend, @capture
    end
    
  end
  
end
