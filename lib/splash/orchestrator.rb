# coding: utf-8
Dir[File.dirname(__FILE__) + '/orchestrator/*.rb'].each {|file| require file  }

module Splash
  module Orchestrator

    class Scheduler
        include Splash::Constants
        include Splash::Helpers
        include Splash::Config
        include Splash::Transports
        include Splash::Orchestrator::Grammar
        def initialize(options = {})
          $stdout.sync = true
          $stderr.sync = true
          @server  = Rufus::Scheduler::new
          @server.extend SchedulerHooks
          @config = get_config
          @result = LogScanner::new
          puts "Splash Orchestrator starting :"
          if options[:scheduling] then
            puts " * Initializing commands Scheduling."
            self.init_commands_scheduling
          end
          sched,value = @config.daemon_logmon_scheduling.flatten
          puts " * Initializing logs monitorings & notifications."
          @server.send sched,value do
            begin
              @result.analyse
              @result.notify
              $stdout.flush
            rescue Errno::ECONNREFUSED
              $stderr.puts "PushGateway seems to be done, please start it."
            end
          end
          hostname = Socket.gethostname
          transport = get_default_subscriber queue: "splash.#{hostname}.input"
          if transport.class == Hash and transport.include? :case then
            splash_exit transport
          end
          transport.subscribe(:block => true) do |delivery_info, properties, body|
            content = YAML::load(body)
            if VERBS.include? content[:verb]
              puts "Receive valid remote order, verb : #{content[:verb].to_s}"
              if content[:payload] then
                res = self.send content[:verb], content[:payload]
              else
                res = self.send content[:verb]
              end
              get_default_client.publish queue: content[:return_to], message: res.to_yaml
            else
              puts "Receive INVALID remote order, verb : #{content[:verb].to_s}"
              get_default_client.publish queue: content[:return_to], message: "Unkown verb #{content[:verb]}".to_yaml
            end
          end
        end

        def terminate
        end

        private
        def init_commands_scheduling
            config = get_config.commands
            commands = config.select{|key,value| value.include? :schedule}.keys
            commands.each do |command|
              sched,value = config[command][:schedule].flatten
              puts "   => Scheduling command #{command.to_s}"
              @server.send sched,value do
                self.execute command: command.to_s
              end
            end

        end

        def execute(options)
          command =  Splash::CommandWrapper::new(options[:command])
          if options[:ack] then
            command.ack
          else
            command.call_and_notify trace: true, notify: true, callback: true
          end
        end

      end


    end

  end
