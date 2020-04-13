# coding: utf-8
module Splash
  module Orchestrator
    module Grammar

      include Splash::Config
      include Splash::Loggers


      VERBS=[:ping,:list_commands,:execute_command,:ack_command, :shutdown]


      def shutdown
        self.terminate
      end

      def ping(payload)
        return "Pong : #{payload[:hostname]} !"
      end


      def list_commands
        return get_config.commands
      end

      def ack_command(payload)
        return self.execute command: payload[:name], ack: true
      end


      def execute_command(payload)
        unless get_config.commands.include? payload[:name].to_sym
          @log.item "Command not found"
          return { :case => :not_found }
        end
        if payload.include? :schedule then
          sched,value = payload[:schedule].flatten
          @log.schedule "remote call command #{payload[:name]}, scheduling : #{sched.to_s} #{value}"
          @server.send sched,value do
            @log.trigger "Executing Scheduled command #{payload[:name]} for Scheduling : #{sched.to_s} #{value}"
            self.execute command: payload[:name]
          end
          return { :case => :quiet_exit }
        else
          @log.info "Execute direct command"
          res = self.execute command: payload[:name]
          return res
        end
      end

    end
  end
end
