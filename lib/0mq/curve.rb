
module ZMQ
  
  # Secure authentication and confidentiality.
  class Curve
    
    # Generate a keypair.
    # Returns a hash with the :public and :private keys.
    def self.keypair
      public_key  = FFI::MemoryPointer.new :char, 41, true
      private_key = FFI::MemoryPointer.new :char, 41, true
      
      rc = LibZMQ::zmq_curve_keypair public_key, private_key
      
      begin
        ZMQ.error_check true if rc==-1
      rescue Errno::EOPNOTSUPP
        raise Errno::EOPNOTSUPP, "Curve requires libzmq to be compiled with libsodium."
      end
      
      { public: public_key.read_string, private: private_key.read_string }
    end
    
  end
  
end
