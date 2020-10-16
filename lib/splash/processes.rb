# coding: utf-8

# base Splash Module
module Splash

  # Processes namespace
  module Processes


    class ProcessNotifier

      @@registry = Prometheus::Client::Registry::new
      @@metric_status = Prometheus::Client::Gauge.new(:process_status, docstring: 'SPLASH metric process status', labels: [:process ])
      @@metric_cpu_percent = Prometheus::Client::Gauge.new(:process_cpu_percent, docstring: 'SPLASH metric process CPU usage in percent', labels: [:process ])
      @@metric_mem_percent = Prometheus::Client::Gauge.new(:process_mem_percent, docstring: 'SPLASH metric process MEM usage in percent', labels: [:process ])
      @@registry.register(@@metric_status)
      @@registry.register(@@metric_cpu_percent)
      @@registry.register(@@metric_mem_percent)


      def initialize(options={})
        @config = get_config
        @url = @config.prometheus_pushgateway_url
        @name = options[:name]
        @status = options[:status]
        @cpu_percent = options[:cpu_percent]
        @mem_percent = options[:mem_percent]
      end

      # send metrics to Prometheus PushGateway
      # @return [Bool]
      def notify
        unless verify_service url: @url then
          return { :case => :service_dependence_missing, :more => "Prometheus Notification not send."}
        end
        @@metric_mem_percent.set(@mem_percent, labels: { process: @name })
        @@metric_cpu_percent.set(@cpu_percent, labels: { process: @name })
        @@metric_status.set(@status, labels: { process: @name })
        hostname = Socket.gethostname
        return Prometheus::Client::Push.new("Splash", hostname, @url).add(@@registry)
      end

    end

    # Processes scanner and notifier
    class ProcessScanner
      include Splash::Constants
      include Splash::Config


      # ProcessScanner Constructor : initialize prometheus metrics
      # @return [Splash::Processes::ProcessScanner]
      def initialize
        @processes_target = Marshal.load(Marshal.dump(get_config.processes))
        @config = get_config
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
        unless verify_service url: @config.prometheus_pushgateway_url then
          return  { :case => :service_dependence_missing, :more => "Prometheus Notification not send." }
        end
        session = (options[:session]) ? options[:session] : log.get_session
        log.info "Sending metrics to Prometheus Pushgateway", session
        @processes_target.each do |item|
          missing = (item[:status] == :missing)? 1 : 0
          val = (item[:status] == :running )? 1 : 0
          processmonitor = ProcessNotifier::new({name: item[:process], status: val , cpu_percent: item[:cpu], mem_percent: item[:mem]})
          if processmonitor.notify then
            log.ok "Sending metrics for process #{item[:process]} to Prometheus Pushgateway", session
          else
            log.ko "Failed to send metrics for process #{item[:process]} to Prometheus Pushgateway", session
          end
        end
        return {:case => :quiet_exit }
      end

    end
  end
end
