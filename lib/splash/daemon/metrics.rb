# coding: utf-8

# base Splash module
module Splash

  # global daemon module
  module Daemon

    # Metrics management modulefor Splash daemon
    module Metrics
      include Splash::Constants
      include Splash::Helpers
      include Splash::Config
      include Splash::Loggers

      @@manager=nil

      # metrics manager factory
      # @return [Splash::Daemon::Metrics::Manager]
      def get_metrics_manager
        return @@manager ||= Manager::new
      end

      # Metrics Manager (collect and sending to Prometheus)
      class Manager

        # metric : commands executions count during Splash daemon uptime
        attr_reader :execution_count
        # metric : logs monitoring count during Splash daemon uptime
        attr_reader :monitoring_logs_count
        # metric : processes monitoring count during Splash daemon uptime
        attr_reader :monitoring_processes_count

        # Constructor prepare prometheus-client, defined metrics and init attributes
        def initialize
          @config = get_config
          @starttime = Time.now
          @execution_count = 0
          @monitoring_logs_count = 0
          @monitoring_processes_count = 0


          @registry = Prometheus::Client::Registry::new
          @metric_uptime = Prometheus::Client::Gauge.new(:splash_uptime, docstring: 'SPLASH self metric uptime')
          @metric_execution = Prometheus::Client::Gauge.new(:splash_execution, docstring: 'SPLASH self metric total commands execution count')
          @metric_logs_monitoring = Prometheus::Client::Gauge.new(:splash_logs_monitoring, docstring: 'SPLASH self metric total logs monitoring count')
          @metric_processes_monitoring = Prometheus::Client::Gauge.new(:splash_processes_monitoring, docstring: 'SPLASH self metric total processes monitoring count')
          @registry.register(@metric_uptime)
          @registry.register(@metric_execution)
          @registry.register(@metric_logs_monitoring)
          @registry.register(@metric_processes_monitoring)
        end

        # virtual accessor uptime
        def uptime
          return Time.now - @starttime
        end

        # increment metric : execution_count
        def inc_execution
          @execution_count += 1
        end

        # increment metric : monitoring_logs_count
        def inc_logs_monitoring
          @monitoring_logs_count += 1
        end

        # increment metric : monitoring_processes_count
        def inc_processes_monitoring
          @monitoring_processes_count += 1
        end

        # Send metrics to Prometheus PushGateway
        # @return [Hash] Exiter case ( :service_dependence_missing , :quiet_exit)
        def notify
          log = get_logger
          session  = get_session
          unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
            return  { :case => :service_dependence_missing, :more => "Prometheus Notification not send." }
          end

          log.debug "Sending Splash self metrics to PushGateway." , session
          @metric_uptime.set uptime
          @metric_execution.set execution_count
          @metric_logs_monitoring.set monitoring_logs_count
          @metric_processes_monitoring.set monitoring_processes_count

          hostname = Socket.gethostname
          url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}"
          Prometheus::Client::Push.new('Splash',hostname, url).add(@registry)
          log.debug "Sending to Prometheus PushGateway done.", session
          return {:case => :quiet_exit }
        end



      end


    end
  end
end
