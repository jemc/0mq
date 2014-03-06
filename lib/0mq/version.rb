
module ZMQ
  
  # Returns a ZMQ::Version object containing the libzmq library version.
  def self.version
    ZMQ::Version
  end
  
  
  # libzmq library version.
  class Version
    
    @version = LibZMQ.version
    
    private_class_method :new
    
    class << self
      
      # :nodoc:
      def major
        @version[:major]
      end
      
      # :nodoc:
      def minor
        @version[:minor]
      end
      
      # :nodoc:
      def patch
        @version[:patch]
      end
      
      # :nodoc:
      def to_s
        "#{@version[:major]}.#{@version[:minor]}.#{@version[:patch]}"
      end
      
      # :nodoc:
      def inspect
        "#{super} \"#{to_s}\""
      end
      
    end
    
  end
  
end
