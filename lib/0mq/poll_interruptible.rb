
module ZMQ
  
  # An interruptible version of Poll.
  class PollInterruptible < Poll
    
    # Creates the additional interruption objects and calls super
    # Note that either #kill or #close MUST be called when done with the object.
    # There is no automatic finalizer for this object.
    def initialize(*sockets)
      @int_sock_rep  = ZMQ::Socket.new ZMQ::REP
      @int_sock_req  = ZMQ::Socket.new ZMQ::REQ
      @int_sock_push = ZMQ::Socket.new ZMQ::PUSH
      @int_sock_pull = ZMQ::Socket.new ZMQ::PULL
      
      # Choose an endpoint name that we can expect to be unique
      # so that they can be shared within the DefaultContext
      int_endpoint = "inproc://__PollInterruptible_int_"+hash.to_s(26)
      
      @int_sock_rep.bind     int_endpoint+'R'
      @int_sock_req.connect  int_endpoint+'R'
      @int_lock_req  = Mutex.new
      @int_sock_pull.bind    int_endpoint+'P'
      @int_sock_push.connect int_endpoint+'P'
      @int_lock_push = Mutex.new
      
      # Interruption blocks are queued until #run receives them.
      # After each is run, the return value is queued in @outerruptions.
      @interruptions = Queue.new
      @outerruptions = Queue.new
      
      @dead = false
      
      super @int_sock_rep, @int_sock_pull, *sockets
    end
    
    # Same as Poll#run, but will yield [nil, nil] to the block if interrupted.
    # Return value may be an empty hash if the poller was killed.
    def run(&block)
      raise "#{self} cannot run; it was permanently killed." if @dead
      
      super do |socket, revents|
        if socket == @int_sock_rep || socket == @int_sock_pull
          key, * = socket.recv_array
          kill = key == "KILL"
          blocking = socket == @int_sock_rep
          
          # Call the user block of #interrupt and store the return value
          unless kill
            result = @interruptions.pop.call
            @outerruptions.push result if blocking
          end
          
          # Call the user block of #run
          block.call nil, nil if block
          
          # Send a response if the interruption was blocking
          socket.send_array ["OKAY"] if blocking
          
          if kill
            @int_sock_rep.close
            @int_sock_pull.close
            @dead = true
          end
        else
          block.call socket, revents if block
        end
      end.tap do |hash|
        hash.delete @int_sock_rep
        hash.delete @int_sock_pull
      end
    end
    
    # Interrupt the running poll loop, but do not clean up.
    # This should be run anytime to let the poller re-evaluate state, etc..
    # This should only be accessed from a thread other than the poll thread,
    #   and only if the poll thread is running
    # If a block is given, it will be executed in the poll thread just
    #   prior to the execution of the user block passed to {#run}.
    # If the blocking: false option is is given, the call will not wait for
    #   the interruption to be processed.
    def interrupt(opts={}, &block)
      blocking = opts.fetch :blocking, true
      block ||= Proc.new { true }
      # block = block.dup
      key = block.object_id.to_s 36
      
      if blocking
        @int_lock_req.synchronize {
          @interruptions.push block     # Store the block to be called
          @int_sock_req.send_string key # Signal an interruption to #run
          @int_sock_req.recv_array      # Wait until it has been handled by #run
        }
        return @outerruptions.pop       # Return the stored result of the block
        
      else
        @int_lock_push.synchronize {
          @interruptions.push block      # Store the block to be called
          @int_sock_push.send_string key # Signal an interruption to #run
        }
        return nil
      end
    end
    
    # Interrupt the running poll loop and permanently kill the Poll object
    # This should be run once, when the Poll object is no longer needed.
    # This should only be accessed from a thread other than the poll thread,
    #   and only if the poll thread is running
    # Use #cleanup instead when there is no poll loop thread running.
    def kill
      return nil if @dead
      
      @int_lock_req.synchronize do
        @int_sock_req.send_array ["KILL"]
        @int_sock_req.recv_array
      end
      
      @int_sock_req.close
      @int_sock_push.close
      
      true
    end
    
    # Permanently kill the Poll object
    # This should be run once, when the Poll object is no longer needed.
    # This should only be accessed when there is no poll thread running.
    # Use #kill instead when there is a poll loop thread running.
    def close
      return nil if @dead
      
      @int_sock_rep.close
      @int_sock_req.close
      @int_sock_pull.close
      @int_sock_push.close
      
      @dead = true
    end
    
    # Return true if the object has been killed or closed and cannot be run
    def dead?
      @dead
    end
    
  end
end
