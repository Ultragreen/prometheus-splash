# coding: utf-8

# base Splash module
module Splash

  # Logs namespace
  module Logs

    class LogsNotifier

      @@registry = Prometheus::Client::Registry::new
      @@metric_missing = Prometheus::Client::Gauge.new(:logmissing, docstring: 'SPLASH metric log missing', labels: [:log ])
      @@metric_count = Prometheus::Client::Gauge.new(:logerrors, docstring: 'SPLASH metric log error', labels: [:log ])
      @@metric_lines = Prometheus::Client::Gauge.new(:loglines, docstring: 'SPLASH metric log lines numbers', labels: [:log ])
      @@registry.register(@@metric_count)
      @@registry.register(@@metric_missing)
      @@registry.register(@@metric_lines)





      def initialize(options={})
        @config = get_config
        @url = @config.prometheus_pushgateway_url
        @name = options[:name]
        @missing = options[:missing]
        @lines = options[:lines]
        @errors = options[:errors]
      end

      # send metrics to Prometheus PushGateway
      # @return [Bool]
      def notify
        unless verify_service url: @url then
          return { :case => :service_dependence_missing, :more => "Prometheus Notification not send."}
        end
        @@metric_missing.set(@missing, labels: { log: @name })
        @@metric_count.set(@errors, labels: { log: @name })
        @@metric_lines.set(@lines, labels: { log: @name })
        hostname = Socket.gethostname
        return Prometheus::Client::Push.new("Splash", hostname, @url).add(@@registry)
      end

    end



    # Log scanner and notifier
    class LogScanner
      include Splash::Constants
      include Splash::Config


      # LogScanner Constructor : initialize prometheus metrics
      # return [Splash::Logs::LogScanner]
      def initialize
        @logs_target = Marshal.load(Marshal.dump(get_config.logs))
        @config = get_config

      end


      # start log analyse for log target in config
      # @return [Hash] Exiter case :quiet_exit
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
      # @return [Hash] the logs structure
      def output
        return @logs_target
      end

      # start notification on prometheus for metric logerrors, logmissing; loglines
      # @param [Hash] options
      # @option options [String] :session a session number for log daemon
      # @return [Hash] Exiter case :quiet_exit
      def notify(options = {})
        log = get_logger
        unless verify_service url: @config.prometheus_pushgateway_url then
          return  { :case => :service_dependence_missing, :more => "Prometheus Notification not send." }
        end
        session = (options[:session]) ? options[:session] : log.get_session
        log.info "Sending metrics to Prometheus Pushgateway", session
        @logs_target.each do |item|
          missing = (item[:status] == :missing)? 1 : 0
          errors = item[:count]
          lines = (item[:lines])? item[:lines] : 0
          name = item[:log]
          logsmonitor = LogsNotifier::new({name: name, missing: missing, errors: errors, lines: lines})
          if logsmonitor.notify then
            log.ok "Sending metrics for log #{name} to Prometheus Pushgateway"
          else
            log.ko "Failed to send metrics for log #{name} to Prometheus Pushgateway"
          end
        end
        return {:case => :quiet_exit }
      end

    end
  end
end
