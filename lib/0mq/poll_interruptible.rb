
module ZMQ
  
  # An interruptible version of Poll.
  class PollInterruptible < Poll
    
    # Creates the additional interruption objects and calls super
    # Note that either #kill or #close MUST be called when done with the object.
    # There is no automatic finalizer for this object.
    def initialize(*sockets)
      @int_context = ZMQ::Context.new
      @int_sock_rep = ZMQ::Socket.new ZMQ::REP, context:@int_context
      @int_sock_req = ZMQ::Socket.new ZMQ::REQ, context:@int_context
      @int_sock_rep.bind    "inproc://int"
      @int_sock_req.connect "inproc://int"
      
      @dead = false
      
      super @int_sock_rep, *sockets
    end
    
    # Same as Poll#run, but will yield [nil, nil] to the block if interrupted
    def run(&block)
      raise "#{self} cannot run; it was permanently killed." if @dead
      
      super do |socket, revents|
        if socket == @int_sock_rep
          result = socket.recv_array
          
          block.call nil, nil if block
          
          socket.send_array ["OKAY"]
          @int_sock_rep.close if result == ["KILL"]
        else
          block.call socket, revents if block
        end
      end.tap { |hash| hash.delete @int_sock_rep }
    end
    
    # Interrupt the running poll loop, but do not clean up.
    # This should be run anytime to let the poller re-evaluate state, etc..
    # This should only be accessed from a thread other than the poll thread,
    #   and only if the poll thread is running
    def interrupt
      @int_sock_req.send_string ""
      @int_sock_req.recv_array
      
      true
    end
    
    # Interrupt the running poll loop and permanently kill the Poll object
    # This should be run once, when the Poll object is no longer needed.
    # This should only be accessed from a thread other than the poll thread,
    #   and only if the poll thread is running
    # Use #cleanup instead when there is no poll loop thread running.
    def kill
      return nil if @dead
      
      @int_sock_req.send_array ["KILL"]
      @int_sock_req.recv_array
      @int_sock_req.close
      @int_context.terminate
      
      @dead = true
    end
    
    # Permanently kill the Poll object
    # This should be run once, when the Poll object is no longer needed.
    # This should only be accessed when there is no poll thread running.
    # Use #kill instead when there is a poll loop thread running.
    def close
      return nil if @dead
      
      @int_sock_rep.close
      @int_sock_req.close
      @int_context.terminate
      
      @dead = true
    end
    
    # Return true if the object has been killed or closed and cannot be run
    def dead?
      @dead
    end
    
    # TODO: add finalizer for cleanup for neglectful user developers
    
  end
end