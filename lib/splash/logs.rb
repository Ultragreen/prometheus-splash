# coding: utf-8
module Splash
  class LogScanner
    include Splash::Constants
    include Splash::Config


    # LogScanner Constructor
    # return [LogScanner]
    def initialize
      @logs_target = get_config.logs
      @config = get_config
      @registry = Prometheus::Client.registry
      @metric_count = Prometheus::Client::Gauge.new(:logerrors, docstring: 'SPLASH metric log error', labels: [:log ])
      @metric_missing = Prometheus::Client::Gauge.new(:logmissing, docstring: 'SPLASH metric log missing', labels: [:log ])
      @metric_lines = Prometheus::Client::Gauge.new(:loglines, docstring: 'SPLASH metric log lines numbers', labels: [:log ])
      @registry.register(@metric_count)
      @registry.register(@metric_missing)
      @registry.register(@metric_lines)
    end


    # start log analyse for log target in config
    def analyse
      @logs_target.each do |record|
        record[:count]=0 if record[:count].nil?
        record[:status] = :clean if record[:status].nil?
        if File.exist?(record[:log]) then
          record[:count] = File.readlines(record[:log]).grep(/#{record[:pattern]}/).size
          record[:status] = :matched if record[:count] > 0
          record[:lines] = `wc -l "#{record[:log]}"`.strip.split(/\s+/)[0].to_i unless record[:status] == :missing
        else
          record[:status] = :missing
        end
      end
    end

    # pseudo-accessor on @logs_target
    def output
      return @logs_target
    end

    # start notification on prometheus for metric logerrors, logmissing; loglines
    def notify
      unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
        $stderr.puts "Prometheus PushGateway Service IS NOT running"
        $stderr.puts "Exit without notification."
        exit 30
      end
      puts "Sending metrics to Prometheus Pushgateway"
      @logs_target.each do |item|
        missing = (item[:status] == :missing)? 1 : 0
        puts " * Sending metrics for #{item[:log]}"
        @metric_count.set(item[:count], labels: { log: item[:log] })
        @metric_missing.set(missing, labels: { log: item[:log] })
        lines = (item[:lines])? item[:lines] : 0
        @metric_lines.set(lines, labels: { log: item[:log] })
      end
      hostname = Socket.gethostname
      url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}"
      Prometheus::Client::Push.new('Splash',hostname, url).add(@registry)
      puts "Sending done."
    end

  end
end
