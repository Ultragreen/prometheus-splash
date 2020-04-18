# coding: utf-8
module Splash
  module Daemon
    module Orchestrator
      module Grammar

        include Splash::Config
        include Splash::Loggers


        VERBS=[:ping,:list_commands,:execute_command,:ack_command, :shutdown]


        def shutdown
          terminate
        end

        def ping(content)
          return "Pong : #{content[:payload][:hostname]} !"
        end


        def list_commands(content)
          return get_config.commands
        end

        def ack_command(content)
          return execute command: content[:payload][:name], ack: true
        end


        def execute_command(content)
          payload = content[:payload]
          unless get_config.commands.include? payload[:name].to_sym
            @log.item "Command not found", content[:session]
            return { :case => :not_found }
          end
          if payload.include? :schedule then
            sched,value = payload[:schedule].flatten
            @log.schedule "remote call command #{payload[:name]}, scheduling : #{sched.to_s} #{value}", content[:session]
            @server.send sched,value do
              @log.trigger "Executing Scheduled command #{payload[:name]} for Scheduling : #{sched.to_s} #{value}", content[:session]
              execute command: payload[:name], session: content[:session]
            end
            return { :case => :quiet_exit }
          else
            @log.info "Execute direct command",  content[:session]
            res = execute command: payload[:name], session: content[:session]
            return res
          end
        end

      end
    end
  end
end
