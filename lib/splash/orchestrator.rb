# coding: utf-8
module Splash
  module Orchestrator

    module SchedulerHooks
      def on_pre_trigger(job, trigger_time)

      end

      def on_post_trigger(job, trigger_time)

      end

      def init_log

      end
    end

    module Commander
      include Splash::Transports
      def send_message (options)
        client = get_default_client
        client.publish  options
      end
    end

    module Grammar

      VERBS=[:ping]

      def ping(payload)
        return "Pong : #{payload[:hostname]} !"
      end
    end

    class Scheduler
        include Splash::Constants
        include Splash::Helpers
        include Splash::Config
        include Splash::Transports
        include Splash::Orchestrator::Grammar
        def initialize
          @server  = Rufus::Scheduler::new
          @server.extend SchedulerHooks
          @server.init_log
          @config = get_config
          @result = LogScanner::new
          sched,value = @config.daemon_logmon_scheduling.flatten
          @server.send sched,value do
            begin
              puts "Notify"
              @result.analyse
              @result.notify
              $stdout.flush
            rescue Errno::ECONNREFUSED
              $stderr.puts "PushGateway seems to be done, please start it."
            end
          end
          hostname = Socket.gethostname
          transport = get_default_subscriber queue: "splash.#{hostname}.input"
          transport.subscribe(:block => true) do |delivery_info, properties, body|
            content = YAML::load(body)
            if VERBS.include? content[:verb]
              res = self.send content[:verb], content[:payload]
              get_default_client.publish queue: content[:return_to], message: res.to_yaml
            else
              get_default_client.publish queue: content[:return_to], message: "Unkown verb #{content[:verb]}".to_yaml
            end
          end
        end

        def terminate
        end

      end


    end

  end
