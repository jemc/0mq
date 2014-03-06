
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
        "#{major}.#{minor}.#{patch}"
      end
      
      # :nodoc:
      def inspect
        "#{super} \"#{to_s}\""
      end
      
      # Compare this version to another version.
      # Examples: "3.2.0", "3.2", "3", 3
      def <=>(value)
        expression = /(?<major>\d+)(\.(?<minor>\d+))?(\.(?<patch>\d+))?/
        
        # Convert both versions into an array of [major, minor, patch].
        this_version = self.to_s
        other_version = value.to_s
        
        this_version =~ expression
        this_set = $~.captures.map { |item| item.to_i if item }.select { |item| item }
        
        other_version =~ expression
        other_set = $~.captures.map { |item| item.to_i if item }.select { |item| item }
        
        # Compare each section (major/minor/patch) of the version number.
        other_set.count.times do |i|
          return  1 if this_set[i] > other_set[i]
          return -1 if this_set[i] < other_set[i]
        end
        
        0 # If the iterator didn't return, the versions are equal.
      end
      
      # :nodoc:
      def ==(value)
        (self <=> value) == 0 ? true : false
      end
      
      # :nodoc:
      def !=(value)
        (self <=> value) != 0 ? true : false
      end
      
      # :nodoc:
      def >(value)
        (self <=> value) == 1 ? true : false
      end
      
      # :nodoc:
      def >=(value)
        (self <=> value) != -1 ? true : false
      end
      
      # :nodoc:
      def <(value)
        (self <=> value) == -1 ? true : false
      end
      
      # :nodoc:
      def <=(value)
        (self <=> value) != 1 ? true : false
      end
      
    end
    
  end
  
end
