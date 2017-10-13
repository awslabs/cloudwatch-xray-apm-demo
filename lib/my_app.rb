require 'logger'
require_relative 'udp/udp_client'
require_relative 'my_services/factorial'
require_relative 'my_services/fibonacci'
require_relative 'xray/helper'

class MyApp
    include MyServices::Factorial
    include MyServices::Fibonacci
    
    def initialize(opts={})
        trap("SIGINT") do
            puts "Shutting down."
            exit
        end
        set_opts(opts)
    end
    
    def run
        while true
            stats = []
            trace_opts = {}

            ###########################################################################
            # Factorial
            ###########################################################################
            n = 5_000
            @logger.info "Calling factorial(#{n})"
            t0 = Time.now
            trace_opts[:my_app] = {start_time: t0}
            factorial(n)
            trace_opts[:factorial] = {
                start_time: t0,
                end_time: Time.now,
                annotations: {
                    input: n,
                }
            }
            factorial_delta = ((trace_opts[:factorial][:end_time] - trace_opts[:factorial][:start_time])*1000).round(6)
            stats << { label: 'factorial', time: factorial_delta }

            ###########################################################################
            # Fibonacci
            ###########################################################################
            n = 35
            @logger.info "Calling fibonacci(#{n})"
            t0 = Time.now
            fibonacci(n)
            trace_opts[:fibonacci] =  {
                start_time: t0,
                end_time: Time.now,
                annotations: {
                    input: n,
                }
            }
            fibonacci_delta = ((trace_opts[:fibonacci][:end_time] - trace_opts[:fibonacci][:start_time])*1000).round(6)
            stats << { label: 'fibonacci', time: fibonacci_delta }

            ###########################################################################
            # Logging
            ###########################################################################
            @logger.info 'Logging metrics'
            t0 = Time.now
            report = "my_app.metrics "
            stats.each_with_index do |stat, i|
                report << ' ' unless i == 0
                report << "#{stat[:label]} #{stat[:time]}"
            end
            @logger.info(report)
            trace_opts[:logging] = {start_time: t0, end_time: Time.now}
            trace_opts[:my_app][:end_time] = Time.now
            
            ###########################################################################
            # Sending custom metrics via UDP
            ###########################################################################
            @collectd_client.send("factorial:#{factorial_delta}|ms\nfibonacci:#{fibonacci_delta}|ms")

            ###########################################################################
            # Sending trace info to X-Ray daemon
            ###########################################################################
            @xray_gen.send_xray_trace(trace_opts)
            sleep 1
        end
    end
    
    private
    
    def set_opts(opts)
        @logger = Logger.new('logs/my_app.log')
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.strftime('%Y-%m-%dT%H:%M:%S.%6N')} #{severity} #{msg}\n"
        end
        @xray_gen = XRay::Helper.new
        @collectd_client = Udp::Client.new
    end
end