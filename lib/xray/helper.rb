require 'json'
require 'logger'
require 'net/http'
require 'socket'
require 'uri'
require_relative 'encoder'

module XRay
    class Helper
        include XRay::Encoder
        
        DEFAULT_DAEMON_HOST = '127.0.0.1'
        DEFAULT_DAEMON_PORT = 2000
        EC2_METADATA_URL = URI.parse("http://169.254.169.254/latest/meta-data")
        EC2_INSTANCEID_PATH = "instance-id"
        EC2_AZ_PATH = "placement/availability-zone"
        
        def initialize(opts={})
            set_opts(opts)
        end

        def send_xray_trace(trace_opts)
            payload = []
            start_time = Time.now
            
            root_key = trace_opts.keys.first
            opts ={}
            subsegs = nil
            if trace_opts && trace_opts.is_a?(Hash)
                trace_opts.each do |trace_key, times_hash|
                    next if trace_key == root_key
                    subsegs ||= []
                    subsegs << get_trace(trace_key.to_s, times_hash[:start_time], times_hash[:end_time], {annotations: times_hash[:annotations]})
                end
                opts[:subsegments] = subsegs
            end
            
            trace = get_trace(root_key.to_s, trace_opts[root_key][:start_time], trace_opts[root_key][:end_time], opts)
            if @instance_id && @az
                trace[:aws] = {
                    ec2: {
                        instance_id: @instance_id,
                        availability_zone: @az
                    }
                }
            end
            payload << get_header.to_json
            payload << trace.to_json
            payload_json = payload.join("\n")
            @xray_client.send(payload_json)
        end

        
        private
        
        def set_opts(opts)
            hostname = opts[:daemon_host] || DEFAULT_DAEMON_HOST
            port = opts[:daemon_port].to_i == 0 ? DEFAULT_DAEMON_PORT : opts[:daemon_port]
            @xray_client = Udp::Client.new(daemon_host: hostname, daemon_port: port)

            http = Net::HTTP.new(EC2_METADATA_URL.host, EC2_METADATA_URL.port)
            http.read_timeout = 1
            http.open_timeout = 1
            @instance_id = http.start() {|http|
                http.get("#{EC2_METADATA_URL}/#{EC2_INSTANCEID_PATH}")
            }.body rescue nil
            @az = http.start() {|http|
                http.get("#{EC2_METADATA_URL}/#{EC2_AZ_PATH}")
            }.body rescue nil
        end
        
    end
end