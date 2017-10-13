require 'socket'

module Udp
    class Client
        DEFAULT_DAEMON_HOST = '127.0.0.1'
        DEFAULT_DAEMON_PORT = 8125
        
        def initialize(opts={})
            set_opts(opts)
        end
        
        def send(payload)
            @socket.send payload, 0 rescue nil
        end
        
        private
        
        def set_opts(opts)
            hostname = opts[:daemon_host] || DEFAULT_DAEMON_HOST
            port = opts[:daemon_port].to_i == 0 ? DEFAULT_DAEMON_PORT : opts[:daemon_port]
            @socket = UDPSocket.new
            @socket.connect(hostname, port)
        end
    end
end