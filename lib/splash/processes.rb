# coding: utf-8

# base Splash Module
module Splash

  # Processes namespace
  module Processes

    # Processes scanner and notifier
    class ProcessScanner
      include Splash::Constants
      include Splash::Config


      # ProcessScanner Constructor : initialize prometheus metrics
      # @return [Splash::Processes::ProcessScanner]
      def initialize
        @processes_target = Marshal.load(Marshal.dump(get_config.processes))
        @config = get_config
        @registry = Prometheus::Client::Registry::new
        @metric_status = Prometheus::Client::Gauge.new(:process_status, docstring: 'SPLASH metric process status', labels: [:process ])
        @metric_cpu_percent = Prometheus::Client::Gauge.new(:process_cpu_percent, docstring: 'SPLASH metric process CPU usage in percent', labels: [:process ])
        @metric_mem_percent = Prometheus::Client::Gauge.new(:process_mem_percent, docstring: 'SPLASH metric process MEM usage in percent', labels: [:process ])
        @registry.register(@metric_status)
        @registry.register(@metric_cpu_percent)
        @registry.register(@metric_mem_percent)

      end


      # start process analyse for process target in config
      # @return [Hash] Exiter case :quiet_exit
      def analyse
        @processes_target.each do |record|
          list =  get_processes patterns: record[:patterns], full: true
          if list.empty?
            record[:status] = :inexistant
            record[:cpu] = 0
            record[:mem] = 0
          else
            record[:status] = :running
            record[:cpu] = list[0]['%CPU']
            record[:mem] = list[0]['%MEM']
          end
        end
        return {:case => :quiet_exit }
      end

      # pseudo-accessor on @processes_target
      # @return [Hash] the processes structure
      def output
        return @processes_target
      end

      # start notification on prometheus for metrics
      # @param [Hash] options
      # @option options [String] :session a session number for log daemon
      # @return [Hash] Exiter case :quiet_exit
      def notify(options = {})
        log = get_logger
        unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
          return  { :case => :service_dependence_missing, :more => "Prometheus Notification not send." }
        end
        session = (options[:session]) ? options[:session] : log.get_session
        log.info "Sending metrics to Prometheus Pushgateway", session
        @processes_target.each do |item|
          missing = (item[:status] == :missing)? 1 : 0
          log.item "Sending metrics for #{item[:process]}", session
          val = (item[:status] == :running )? 1 : 0
          @metric_status.set(val, labels: { process: item[:process] })
          @metric_cpu_percent.set(item[:cpu], labels: { process: item[:process] })
          @metric_mem_percent.set(item[:mem], labels: { process: item[:process] })
        end
        hostname = Socket.gethostname
        url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}/#{@config.prometheus_pushgateway_path}"
        Prometheus::Client::Push.new('Splash',hostname, url).add(@registry)
        log.ok "Sending to Prometheus PushGateway done.", session
        return {:case => :quiet_exit }
      end

    end
  end
end
