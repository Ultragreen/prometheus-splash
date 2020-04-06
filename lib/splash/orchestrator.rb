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


    class Scheduler
        include Splash::Constants
        include Splash::Helpers
        include Splash::Config
        def initialize
          @server  = Rufus::Scheduler::new
          @server.extend SchedulerHooks
          @server.init_log
          @result = LogScanner::new
          @server.every '20s' do
            begin
              puts "Notify"
              @result.analyse
              @result.notify
              $stdout.flush
            rescue Errno::ECONNREFUSED
              $stderr.puts "PushGateway seems to be done, please start it."
            end
          end
          @server.join
        end

        def terminate
        end

      end


    end

  end
