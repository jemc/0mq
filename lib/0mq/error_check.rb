
module ZMQ
  
  # "Native 0MQ error codes"
  # Each is defined in zmq.h and is not a standard errno code
  # Description for each error code is paraphrased from the zmq man pages
  {
    :EFSM           => "Finite state machine is in the wrong state",
    :ENOCOMPATPROTO => "The requested protocol is not compatible",
    :ETERM          => "The context was terminated",
    :EMTHREAD       => "No I/O thread is available to accomplish the task",
  }.each do |name, message|
    klass = Class.new SystemCallError do
      define_singleton_method :exception do |*args|
        super(*args)
        .tap { |exc| exc.define_singleton_method(:message) { message } }
        .tap { |exc| exc.define_singleton_method(:to_s)    { message } }
        .tap { |exc| exc.define_singleton_method(:inspect) { 
          "#<Errno::#{name}: #{message}>"
        } }
      end
    end
    
    klass.const_set :Errno, ZMQ.const_get(name)
    Errno.const_set name, klass
  end
  
  
  # A hash of error number => exception class.
  # Example: 1 => Errno::EPERM
  @error_map = Hash.new
  
  Errno.constants
    .map    { |x| Errno.const_get x }
    .select { |x| x.is_a?(Class) && x < SystemCallError }
    .each   { |x| @error_map[x.const_get(:Errno)] = x }
  
  
  # Checks the libzmq global error number and raises it as an exception.
  # Should be used after calling a libzmq resource that returns -1 on error.
  # Example: ZMQ.error_check if rc == -1
  def self.error_check(adjust_backtrace=false)
    errno = LibZMQ.zmq_errno
    return true if errno == 25 # TODO: What is this for? Remove?
    
    backtrace = adjust_backtrace ? caller[0...-2] : caller
    if @error_map.has_key? errno
      raise @error_map[errno], '', backtrace
    else
      raise SystemCallError, errno.to_s, backtrace
    end
  end
  
end