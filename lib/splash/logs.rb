# coding: utf-8
module Splash
  module Logs
    class LogScanner
      include Splash::Constants
      include Splash::Config


      # LogScanner Constructor
      # return [LogScanner]
      def initialize
        @logs_target = get_config.logs
        @config = get_config
        @registry = Prometheus::Client::Registry::new
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
        return {:case => :quiet_exit }
      end

      # pseudo-accessor on @logs_target
      def output
        return @logs_target
      end

      # start notification on prometheus for metric logerrors, logmissing; loglines
      def notify(options = {})
        log = get_logger
        unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
          return  { :case => :service_dependence_missing, :more => "Prometheus Notification not send." }
        end
        session = (options[:session]) ? options[:session] : log.get_session
        log.info "Sending metrics to Prometheus Pushgateway", session
        @logs_target.each do |item|
          missing = (item[:status] == :missing)? 1 : 0
          log.item "Sending metrics for #{item[:log]}", session
          @metric_count.set(item[:count], labels: { log: item[:log] })
          @metric_missing.set(missing, labels: { log: item[:log] })
          lines = (item[:lines])? item[:lines] : 0
          @metric_lines.set(lines, labels: { log: item[:log] })
        end
        hostname = Socket.gethostname
        url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}"
        Prometheus::Client::Push.new('Splash',hostname, url).add(@registry)
        log.ok "Sending to Prometheus PushGateway done.", session
        return {:case => :quiet_exit }
      end

    end
  end
end
