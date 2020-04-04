
module Splash
  module LogsMonitor
    module DaemonController
      include Splash::Constants
      include Splash::Helpers
      include Splash::Config

      def startdaemon(options = {})
        config = get_config
        unless verify_service host: config.prometheus_pushgateway_host ,port: config.prometheus_pushgateway_port then
          $stderr.puts "Prometheus PushGateway Service is not running,"
          $stderr.puts " please start before running Splash daemon."
          exit 11
        end

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
          errorcode = 0
          if File.exist?(config.full_pid_path) then

            begin
              pid = `cat #{config.full_pid_path}`.to_i
              Process.kill("TERM", pid)
            rescue Errno::ESRCH
              $stderr.puts "Process of PID : #{pid} not found"
              errorcode = 12
            end
            FileUtils::rm config.full_pid_path if File::exist? config.full_pid_path
          else
            $stderr.puts "Splash is not running"
            errorcode = 13
          end
          return errorcode
      end

    end
  end
end
