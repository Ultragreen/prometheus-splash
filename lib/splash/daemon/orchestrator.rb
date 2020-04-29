# coding: utf-8
Dir[File.dirname(__FILE__) + '/orchestrator/*.rb'].each {|file| require file  }

# base Splash module
module Splash

  # global daemon module
  module Daemon

    # orchestrator specific module
    module Orchestrator

      # Splash Scheduler object
      class Scheduler
        include Splash::Constants
        include Splash::Helpers
        include Splash::Config
        include Splash::Transports
        include Splash::Daemon::Orchestrator::Grammar
        include Splash::Loggers
        include Splash::Logs
        include Splash::Processes
        include Splash::Commands

        # Constructor prepare the Scheduler
        # commands Schedules
        # logs monitorings
        # process monitorings
        # @param [Hash] options
        # @option options [Symbol] :scheduling activate commands scheduling
        def initialize(options = {})
          @log = get_logger
          self.extend Splash::Daemon::Metrics
          @metric_manager = get_metrics_manager
          $stdout.sync = true
          $stderr.sync = true
          @server  = Rufus::Scheduler::new
          @server.extend SchedulerHooks
          @config = get_config

          @log.info "Splash Orchestrator starting :"
          if options[:scheduling] then
            @log.item "Initializing commands Scheduling."
            init_commands_scheduling
          end

          if @config.logs.empty? then
            @log.item "No logs to monitor"
          else
            sched,value = @config.daemon_procmon_scheduling.flatten
            @log.item "Initializing logs monitorings & notifications."
            @log_result = LogScanner::new
            @server.send sched,value do
              begin
                session = get_session
                @metric_manager.inc_logs_monitoring
                @log.trigger "Logs monitoring for Scheduling : #{sched.to_s} #{value.to_s}", session
                @log_result.analyse
                @log_result.notify :session => session
              rescue Errno::ECONNREFUSED
                @log.error "PushGateway seems to be done, please start it.", session
              end
            end
          end

          if @config.processes.empty? then
            @log.item "No processes to monitor"
          else
            sched,value = @config.daemon_logmon_scheduling.flatten
            @log.item "Initializing processes monitorings & notifications."
            @process_result = ProcessScanner::new
            @server.send sched,value do
              begin
                session = get_session
                @metric_manager.inc_processes_monitoring
                @log.trigger "Processes monitoring for Scheduling : #{sched.to_s} #{value.to_s}", session
                @process_result.analyse
                @process_result.notify :session => session
              rescue Errno::ECONNREFUSED
                @log.error "PushGateway seems to be done, please start it.", session
              end
            end
          end


          sched,value = @config.daemon_metrics_scheduling.flatten
          @log.item "Initializing Splash metrics notifications."
          @server.send sched,value do
            begin
              @metric_manager.notify
            rescue Errno::ECONNREFUSED
              @log.error "PushGateway seems to be done, please start it."
            end
          end

          hostname = Socket.gethostname
          transport = get_default_subscriber queue: "splash.#{hostname}.input"
          if transport.class == Hash and transport.include? :case then
            splash_exit transport
          end
          transport.subscribe(:block => true) do |delivery_info, properties, body|
            content = YAML::load(body)
            session = get_session
            content[:session] = session
            if VERBS.include? content[:verb]
              @log.receive "Valid remote order, verb : #{content[:verb].to_s}", session
              res = self.send content[:verb], content
              get_default_client.publish queue: content[:return_to], message: res.to_yaml
              @log.send "Result to #{content[:return_to]}.", session
            else
              @log.receive "INVALID remote order, verb : #{content[:verb].to_s}", session
              get_default_client.publish queue: content[:return_to], message: "Unkown verb #{content[:verb]}".to_yaml
            end
          end
        end

        # Stop the Splash daemon gracefully
        # @return [hash] Exiter Case :quiet_exit
        def terminate
          @log.info "Splash daemon shutdown"
          @server.shutdown
          change_logger logger: :cli
          splash_exit case: :quiet_exit
        end

        private
        # prepare commands Scheduling
        def init_commands_scheduling
          config = get_config.commands
          commands = config.select{|key,value| value.include? :schedule}.keys
          commands.each do |command|
            sched,value = config[command][:schedule].flatten
            @log.arrow "Scheduling command #{command.to_s}"
            @server.send sched,value do
              session  = get_session
              @log.trigger "Executing Scheduled command #{command.to_s} for Scheduling : #{sched.to_s} #{value.to_s}", session
              execute command: command.to_s, session: session
            end
          end

        end

        # execute_command verb : execute command specified in payload
        # @param [Hash] options
        # @option options [Symbol] :command the name of the command
        # @option options [Symbol] :ack ack flag to inhibit execution and send ack to Prometheus (0)
        # @return [Hash] Exiter case
        def execute(options)
          command =  CommandWrapper::new(options[:command])
          if options[:ack] then 
          else
            @metric_manager.inc_execution
            return command.call_and_notify trace: true, notify: true, callback: true, session: options[:session]
          end
        end

      end

    end
  end
end
