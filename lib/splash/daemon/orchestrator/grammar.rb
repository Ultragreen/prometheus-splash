# coding: utf-8

# base Splash module
module Splash

  # global daemon module
  module Daemon

    # orchestrator specific module
    module Orchestrator

      # Orchestrator grammar method defiition  module
      module Grammar

        include Splash::Config
        include Splash::Loggers

        # list of known verbs for Splash orchestrator
        VERBS=[:ping,:list_commands,:execute_command,:ack_command, :shutdown, :get_jobs, :reset]

        # shutdown verb : stop the Splash daemon gracefully
        # @param [Hash] content message content Hash Structure, ignored
        # @return [Hash] Exiter Case :quiet_exit
        def shutdown(content)
          terminate
        end

        # ping verb : return pong to hostname precise in payload
        # @param [Hash] content message content Hash Structure, include  mandatory payload[:hostname]
        # @return [String] the pong
        def ping(content)
          return "Pong : #{content[:payload][:hostname]} !"
        end

        # list_commands verb : return the list of specified commands in local Splash
        # @param [Hash] content message content Hash Structure, ignored
        # @return [Hash] structure of commands
        def list_commands(content)
          return get_config.commands
        end

        # ack_command verb : send ack to Prometheus, for command specified in payload
        # @param [Hash] content message content Hash Structure, include  mandatory payload[:name]
        # @return [Hash] Exiter case
        def ack_command(content)
          return execute command: content[:payload][:name], ack: true
        end


        # get_jobs verb : return list of scheduled jobs for internal scheduler
        # @param [Hash] content message content Hash Structure, ignored
        # @return [String] YAML dataset
        def get_jobs(content)
          return @server.jobs.to_yaml
        end

        # reset verb : reset the internal scheduler
        # @param [Hash] content message content Hash Structure, ignored
        # @return [String] "Scheduler reset" static
        def reset(content)
          return "Scheduler reset" if reset_orchestrator
        end

        # execute_command verb : execute command specified in payload
        # @param [Hash] content message content Hash Structure, include  mandatory payload[:name]
        # @return [Hash] Exiter case
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
