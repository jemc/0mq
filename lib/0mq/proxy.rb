
module ZMQ
  
  # The proxy connects a frontend socket to a backend socket. Conceptually,
  # data flows from frontend to backend. Depending on the socket types,
  # replies may flow in the opposite direction. The direction is conceptual
  # only; the proxy is fully symmetric and there is no technical difference
  # between frontend and backend.
  class Proxy
    
    # Create a running proxy object.
    def self.proxy(frontend, backend, capture = nil)
      new(frontend, backend, capture).tap { |p| p.run }
    end
    
    # Accepts a frontend, backend, and optional capture socket.
    # See http://api.zeromq.org/4-0:zmq-proxy
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
