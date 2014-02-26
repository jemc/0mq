
module ZMQ
  
  ErrorMap = Hash.new
  
  Errno.constants
       .map    { |x| Errno.const_get x }
       .select { |x| x.is_a?(Class) && x < SystemCallError }
       .each   { |x| ErrorMap[x.const_get(:Errno)] = x }
  
  def self.error_check(adjust_backtrace=false)
    errno = LibZMQ.zmq_errno
    return true if errno == 25
    
    # str = LibZMQ.zmq_strerror(errno).read_string
    str = ''
    raise ErrorMap[errno], str, caller[0...-2]
  end
  
end