# coding: utf-8
module Splash
  module Orchestrator
    module Grammar

      include Splash::Config
      VERBS=[:ping,:list_commands,:execute_command,:ack_command]

      def ping(payload)
        return "Pong : #{payload[:hostname]} !"
      end


      def list_commands
        return get_config.commands
      end

      def ack_command
        return self.execute command: payload[:name], ack: true
      end


      def execute_command(payload)
        unless get_config.commands.include? payload[:name].to_sym
          puts " * Command not found"
          return { :case => :not_found }
        end
        if payload.include? :schedule then
          sched,value = payload[:schedule].flatten
        else
          sched = :in
          value = '1s'
        end
        puts " * Schedule remote call command #{payload[:name]}, scheduling : #{sched.to_s} #{value}"
        @server.send sched,value do
          self.execute command: payload[:name]
        end
        return { :case => :quiet_exit }
      end

    end
  end
end
