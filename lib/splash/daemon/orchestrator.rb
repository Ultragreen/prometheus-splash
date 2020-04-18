# coding: utf-8
Dir[File.dirname(__FILE__) + '/orchestrator/*.rb'].each {|file| require file  }

module Splash
  module Daemon
    module Orchestrator

      class Scheduler
        include Splash::Constants
        include Splash::Helpers
        include Splash::Config
        include Splash::Transports
        include Splash::Daemon::Orchestrator::Grammar
        include Splash::Loggers
        include Splash::Logs
        include Splash::Commands

        def initialize(options = {})
          @log = get_logger
          $stdout.sync = true
          $stderr.sync = true
          @server  = Rufus::Scheduler::new
          @server.extend SchedulerHooks
          @config = get_config
          @result = LogScanner::new
          @log.info "Splash Orchestrator starting :"
          if options[:scheduling] then
            @log.item "Initializing commands Scheduling."
            init_commands_scheduling
          end
          sched,value = @config.daemon_logmon_scheduling.flatten
          @log.item "Initializing logs monitorings & notifications."
          @server.send sched,value do
            begin
              session = get_session
              @log.trigger "Logs monitoring for Scheduling : #{sched.to_s} #{value.to_s}", session
              @result.analyse
              @result.notify :session => session
            rescue Errno::ECONNREFUSED
              @log.error "PushGateway seems to be done, please start it.", session
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

        def terminate
          @log.info "Splash daemon shutdown"
          @server.shutdown
          change_logger logger: :cli
          splash_exit case: :quiet_exit
        end

        private
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

        def execute(options)
          command =  CommandWrapper::new(options[:command])
          if options[:ack] then
            command.ack
          else
            return command.call_and_notify trace: true, notify: true, callback: true, session: options[:session]
          end
        end

      end

    end
  end
end
