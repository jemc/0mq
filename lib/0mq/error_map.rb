
module ZMQ
  
  # A hash of error number => exception class.
  # Example: 1 => Errno::EPERM
  ErrorMap = Hash.new
  
  Errno.constants
    .map    { |x| Errno.const_get x }
    .select { |x| x.is_a?(Class) && x < SystemCallError }
    .each   { |x| ErrorMap[x.const_get(:Errno)] = x }
  
  
  # Checks the libzmq global error number and raises it as an exception.
  # Should be used after calling a libzmq resource that returns -1 on error.
  # Example: ZMQ.error_check if rc == -1
  def self.error_check(adjust_backtrace=false)
    errno = LibZMQ.zmq_errno
    return true if errno == 25 # TODO: What is this for? Remove?
    
    backtrace = adjust_backtrace ? caller[0...-2] : caller
    if ErrorMap.has_key? errno
      raise ErrorMap[errno], '', backtrace
    else
      raise SystemCallError, errno.to_s, backtrace
    end
  end
  
end