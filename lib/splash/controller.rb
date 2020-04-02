
module Splash
  module LogsMonitor
    module DaemonController
      include Splash::Constants
      include Splash::Helpers

      def startdaemon(options = {})
        unless File::exist? "/tmp/splash.pid" then
          return daemonize :description => "Splash : daemon", :pid_file => "/tmp/splash.pid" do
            while true
              sleep 5
              @config_file = CONFIG_FILE
              result = LogScanner::new(@config_file)
              result.analyse
              result.notify
            end
          end
        end
      end

      def stopdaemon(options = {})
        if File::exist? "/tmp/splash.pid" then
          Process.kill("TERM", `cat /tmp/splash.pid`.to_i)
          FileUtils::rm "/tmp/splash.pid"
          return true
        end
      end

    end
  end
end
