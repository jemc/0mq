
module ZMQ
  
  class Socket
    
    @@get_options = {
      :RCVMORE             => :bool,
      :RCVHWM              => :int,
      :AFFINITY            => :uint64,
      :IDENTITY            => :string,
      :RATE                => :int,
      :RECOVERY_IVL        => :int,
      :SNDBUF              => :int,
      :RCVBUF              => :int,
      :LINGER              => :int,
      :RECONNECT_IVL       => :int,
      :RECONNECT_IVL_MAX   => :int,
      :BACKLOG             => :int,
      :MAXMSGSIZE          => :int64,
      :MULTICAST_HOPS      => :int,
      :RCVTIMEO            => :int,
      :SNDTIMEO            => :int,
      :IPV6                => :bool,
      :IPV4ONLY            => :bool,
      :IMMEDIATE           => :bool,
      :FD                  => :int,
      :EVENTS              => :int,
      :LAST_ENDPOINT       => :string,
      :TCP_KEEPALIVE       => :int,
      :TCP_KEEPALIVE_IDLE  => :int,
      :TCP_KEEPALIVE_CNT   => :int,
      :TCP_KEEPALIVE_INTVL => :int,
      :MECHANISM           => :int,
      :PLAIN_SERVER        => :int,
      :PLAIN_USERNAME      => :string,
      :PLAIN_PASSWORD      => :string,
      :CURVE_PUBLICKEY     => :string,
      :CURVE_SECRETKEY     => :string,
      :CURVE_SERVERKEY     => :string,
      :ZAP_DOMAIN          => :string,
    }
    
    @@set_options = {
      :SNDHWM              => :int,
      :RCVHWM              => :int,
      :AFFINITY            => :uint64,
      :SUBSCRIBE           => :string,
      :UNSUBSCRIBE         => :string,
      :IDENTITY            => :string,
      :RATE                => :int,
      :RECOVERY_IVL        => :int,
      :SNDBUF              => :int,
      :RCVBUF              => :int,
      :LINGER              => :int,
      :RECONNECT_IVL       => :int,
      :RECONNECT_IVL_MAX   => :int,
      :RECONNECT_IVL       => :int,
      :BACKLOG             => :int,
      :MAXMSGSIZE          => :int64,
      :MULTICAST_HOPS      => :int,
      :RCVTIMEO            => :int,
      :SNDTIMEO            => :int,
      :IPV6                => :bool,
      :IPV4ONLY            => :bool,
      :IMMEDIATE           => :bool,
      :ROUTER_HANDOVER     => :int,
      :ROUTER_MANDATORY    => :int,
      :ROUTER_RAW          => :int,
      :PROBE_ROUTER        => :int,
      :XPUB_VERBOSE        => :int,
      :REQ_CORRELATE       => :int,
      :REQ_RELAXED         => :int,
      :TCP_KEEPALIVE       => :int,
      :TCP_KEEPALIVE_IDLE  => :int,
      :TCP_KEEPALIVE_CNT   => :int,
      :TCP_KEEPALIVE_INTVL => :int,
      :TCP_ACCEPT_FILTER   => :string,
      :PLAIN_SERVER        => :int,
      :PLAIN_USERNAME      => :string,
      :PLAIN_PASSWORD      => :string,
      :CURVE_SERVER        => :int,
      :CURVE_PUBLICKEY     => :string,
      :CURVE_SECRETKEY     => :string,
      :CURVE_SERVERKEY     => :string,
      :ZAP_DOMAIN          => :string,
      :CONFLATE            => :bool,
    }
    
    # Set up map of option codes to option types
    @@option_types = {}
    @@get_options.each_pair { |n,t| @@option_types[ZMQ.const_get(n)] = t }
    @@set_options.each_pair { |n,t| @@option_types[ZMQ.const_get(n)] = t }
    
  public
    
    # Define the socket option reader methods
    @@get_options.keys.each do |name|
      code = ZMQ.const_get(name)
      # Get the given socket option
      define_method(name.downcase) { get_opt code }
    end
    
    # Define the socket option writer methods
    @@set_options.keys.each do |name|
      code = ZMQ.const_get(name)
      name = :"#{name}=" unless [:SUBSCRIBE, :UNSUBSCRIBE].include? name
      # Set the given socket option
      define_method(name.downcase) { |val| set_opt code, val }
    end
    
  end
  
end
