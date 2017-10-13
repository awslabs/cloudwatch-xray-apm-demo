require 'time'
require 'securerandom'
require 'socket'

module XRay
    module Encoder
                
        def get_header
            {format: 'json', version: 1}
        end

        def get_dynamo_trace(table_name, start_time, end_time)
            hash = get_http_trace('DynamoDB', nil, start_time, end_time)
            hash[:aws] = {
                table_name: table_name,
                operation: 'UpdateItem',
                request_id: '3AIENM5J4ELQ3SPODHKBIRVIC3VV4KQNSO5AEMVJF66Q9ASUAAJG',
                resource_names: [table_name]
            }
            hash
        end
        
        def get_http_trace(name, url, start_time, end_time, opts={})
            hash = get_trace(name, start_time, end_time, opts)
            
            opts[:request] ||= {}
            opts[:request][:method] ||= 'GET'
            opts[:request][:client_ip] ||= my_first_ipv4
            opts[:request][:url] ||= url
            opts[:request][:user_agent] ||= "my_user_agent"
            opts[:request][:x_forwarded_for] ||= "true"
            opts[:response] ||= {}
            opts[:response][:status] ||= 200
            hash[:http] = opts
            hash
        end
        
        def get_trace(name, start_time, end_time, opts={})
            # AWS::EC2::Instance
            # AWS::ECS::Container
            # AWS::ElasticBeanstalk::Environment
            opts[:origin] ||= 'AWS::EC2::Instance'
            hash = {
                name: name,
                id: generate_id,
                start_time: encode_time(start_time),
                trace_id: encode_trace_id(start_time),
                end_time: encode_time(end_time),
                origin: opts[:origin],
            }
            hash[:annotations] = opts[:annotations] if opts[:annotations]
            
            if opts[:subsegments] && opts[:subsegments].is_a?(Array)
                opts[:subsegments].each_with_index do |subseg, i|
                    subseg[:traced] = true

                    hash[:subsegments] ||= []
                    hash[:subsegments] << subseg.dup
                    hash[:subsegments][i][:id] = generate_id
                end
            end
            hash
        end
                
        def encode_time(recorded_at)
            float_epoch_time = nil

            if recorded_at.is_a?(Time) || recorded_at.is_a?(Fixnum)
                float_epoch_time = recorded_at.to_f
            elsif recorded_at.is_a?(Float)
                float_epoch_time = recorded_at
            else
                raise "Invalid recorded_at class: #{recorded_at.class}. It must be a Float in epoch time."
            end
        
            float_epoch_time
        end
    
        def generate_id
            SecureRandom.hex(8)
        end

        def encode_trace_id(recorded_at=Time.now, uuid=nil, version=nil)
            version ||= 1
            hex_recorded_at = recorded_at.to_i.to_s(16)
            uuid = SecureRandom.hex(12)
            "#{version}-#{hex_recorded_at}-#{uuid}"
        end
        
        def my_first_private_ipv4
          Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
        end

        def my_first_public_ipv4
          Socket.ip_address_list.detect{|intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private?}
        end
        
        def my_first_ipv4
            my_first_public_ipv4.ip_address unless my_first_public_ipv4.nil?
        end
    end 
end