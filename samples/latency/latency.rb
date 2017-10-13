#!/usr/bin/env ruby

require 'logger'
require 'socket'

count = ARGV[1].to_i
count = count > 0 ? count : 100000

port = ARGV[0].to_i
port = port > 0 ? port : 2000

###############################################################################
# Logging task
###############################################################################
logger = Logger.new('logs/lattency_test.log')
logger.info "Make sure log file is created before we measure the logging time."
puts "Logging #{count} lines ..."
t0 = Time.now
count.times do |i|
    logger.info "i = #{i}"
end
delta = (Time.now-t0).round(6)
report = {}
report[:logs] = { total: delta, throughput: (count/delta).round(6) }

###############################################################################
# UDP task
###############################################################################
socket = UDPSocket.new
socket.connect("127.0.0.1", port)
puts "Sending #{count} messages via UDP to localhost on port #{port} ..."
t0 = Time.now
count.times do |i|
    socket.send "i:#{i}|c\n", 0
end
delta = (Time.now-t0).round(6)
report[:udp] = { total: delta, throughput: (count/delta).round(6) }
socket.close

puts
puts "-------------------------------------------------------------------------"
puts "|     task     |     total time (sec)     | Throughput (operations/sec) |"
puts "-------------------------------------------------------------------------"
puts "     log               #{report[:logs][:total]}              #{report[:logs][:throughput]}            "
puts "     udp               #{report[:udp][:total]}              #{report[:udp][:throughput]}           "
