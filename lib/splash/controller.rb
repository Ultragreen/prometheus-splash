
module Splash
  module LogsMonitor
    module DaemonController
      include Splash::Constants
      include Splash::Helpers
      include Splash::Config

      def startdaemon(options = {})
        config = get_config
        unless File::exist? config.full_pid_path then
          return daemonize :description => config.daemon_process_name,
                           :pid_file => config.full_pid_path,
                           :daemon_user => config.daemon_user,
                           :daemon_group => config.daemon_group,
                           :stdout_trace => config.full_stdout_trace_path,
                           :stderr_trace => config.full_stderr_trace_path do
            result = LogScanner::new
            while true
              sleep 5
              puts "Notify"
              result.analyse
              result.notify
            end
          end
        end
      end

      def stopdaemon(options = {})
          config = get_config
          if File.exist?(config.full_pid_path) then

            begin
              pid = `cat #{config.full_pid_path}`.to_i
              Process.kill("TERM", pid)
            rescue Errno::ESRCH
              puts "Process of PID : #{pid} not found"
            end
              FileUtils::rm config.full_pid_path if File::exist? config.full_pid_path
            return true
          else
            return false
          end
      end

    end
  end
end
