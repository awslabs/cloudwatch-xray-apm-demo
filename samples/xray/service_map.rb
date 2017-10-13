#!/usr/bin/env ruby

require 'json'
require_relative '../../lib/xray/encoder'
require_relative '../../lib/udp/udp_client'

include XRay::Encoder

@xray_client = Udp::Client.new(daemon_host: '127.0.0.1', daemon_port: 2000)
payload = []
start_time = Time.now
@total_trace_time = 0.04 # ms
trace1 = get_http_trace('acmeFrontend', 'http://acme.com/frontend', start_time, start_time + @total_trace_time)
trace2 = get_http_trace('acmeService1', 'http://api.acme.com/service1', start_time+0.002, start_time + (@total_trace_time/2))
trace2[:namespace] = 'remote'
trace2[:traced] = true
trace3 = get_dynamo_trace('myTable', start_time + (@total_trace_time/2), start_time + (@total_trace_time/2)+0.01)
trace2[:namespace] = 'remote'
trace2[:traced] = true


trace1[:subsegments] ||= []

trace1[:subsegments] << trace2.dup
trace1[:subsegments][0][:id] = generate_id

trace1[:subsegments] << trace3.dup
trace1[:subsegments][1][:id] = generate_id


payload << get_header.to_json
payload << trace1.to_json

payload_json = payload.join("\n")
@xray_client.send(payload_json)





# def send_trace
#     payload = []
#     start_time = Time.now
#
#     trace1 = get_http_trace('acmeFrontend', 'http://acme.com', start_time, start_time + @total_trace_time)
#     trace2 = get_http_trace('acmeService1', 'http://api.acme.com/service1', start_time+0.002, start_time + (@total_trace_time/2))
#     trace2[:namespace] = 'remote'
#     trace2[:traced] = true
#
#     trace1[:subsegments] ||= []
#     trace1[:subsegments] << trace2.dup
#     trace1[:subsegments][0][:id] = generate_id
#
#     # trace2[:trace_id] = trace1[:trace_id]
#     # trace2[:parent_id] = trace1[:subsegments][0][:id] = generate_id
#
#
#     payload << get_header.to_json
#     payload << trace1.to_json
#     # payload << get_header.to_json
#     # payload << trace2.to_json
#     payload_json = payload.join("\n")
#     @logger.info payload_json
#     @socket.send payload_json, 0
# end