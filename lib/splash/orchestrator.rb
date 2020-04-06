require 'rufus-scheduler'

module Splash
  module Orchestrator



    module SchedulerHooks
      def on_pre_trigger(job, trigger_time)

      end

      def on_post_trigger(job, trigger_time)
      
      end

      def init_log

      end

      class Scheduler
        def initialize
          @server  = Rufus::Scheduler::new
          @server.extend SchedulerHooks
          @server.init_log
          @server.join
          @server.schedule
        end

        def terminate
        end

        def schedule(content = {})
              # :type: :every
              #        :at
              #        :in
              #        :cron



          @server.send content[:type],  content[:value], nil, opts , &aproc
        end

      end

    end
  end
end
