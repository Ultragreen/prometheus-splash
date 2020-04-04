
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
          res = daemonize :description => config.daemon_process_name,
              :pid_file => config.full_pid_path,
              :daemon_user => config.daemon_user,
              :daemon_group => config.daemon_group,
              :stdout_trace => config.full_stdout_trace_path,
              :stderr_trace => config.full_stderr_trace_path do
            result = LogScanner::new
            while true
              begin
                sleep 5
                puts "Notify"
                result.analyse
                result.notify
              rescue Errno::ECONNREFUSED
                $stderr.puts "PushGateway seems to be done, please start it."
              end
            end
          end
          if res == 0 then
            pid = `cat #{config.full_pid_path}`.to_i
            puts "Splash Daemon Started, with PID : #{pid}"
          else
            $stderr.puts "Splash Daemon loading error"
          end
          return res

        else
          $stderr.puts "Pid File already exist, please verify if Splash daemon is running."
          return 14
        end
      end

      def stopdaemon(options = {})
          config = get_config
          errorcode = 0
          if File.exist?(config.full_pid_path) then

            begin
              pid = `cat #{config.full_pid_path}`.to_i
              Process.kill("TERM", pid)
              puts 'Splash stopped succesfully'
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

      def statusdaemon
        config = get_config
        pid = realpid = ''
        pid = `cat #{config.full_pid_path}`.to_s if File.exist?(config.full_pid_path)
        realpid = get_process pattern: get_config.daemon_process_name
        pid.chomp!
        realpid.chomp!
        unless realpid.empty? then
          print "Splash Process is running with PID #{realpid} "
        else
          print 'Splash Process not found '
        end
        unless pid.empty? then
          puts "and PID file exist with PID #{pid}"
        else
          puts "and PID file don't exist"
        end
        if pid == realpid then
          puts 'Status OK'
          return 0
        elsif pid.empty? then
          $stderr.puts "PID File error, you have to kill process manualy, with : '(sudo )kill -TERM #{realpid}'"
          $stderr.puts "Status KO"
          return 16
        elsif realpid.empty? then
          $stderr.puts "Process Splash Dameon missing, run 'splash daemon stop' to reload properly"
          $stderr.puts "Status KO"
          return 17
        end
      end

    end
  end
end
