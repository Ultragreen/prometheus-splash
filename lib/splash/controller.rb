# coding: utf-8
module Splash
  module LogsMonitor
    module DaemonController
      include Splash::Constants
      include Splash::Helpers
      include Splash::Config
      include Splash::Orchestrator

      def startdaemon(options = {})
        config = get_config
        unless verify_service host: config.prometheus_pushgateway_host ,port: config.prometheus_pushgateway_port then
          return {:case => :service_dependence_missing, :more => 'Prometheus Gateway'}
        end

        unless File::exist? config.full_pid_path then
          res = daemonize :description => config.daemon_process_name,
              :pid_file => config.full_pid_path,
              :stdout_trace => config.full_stdout_trace_path,
              :stderr_trace => config.full_stderr_trace_path do
              Scheduler::new
          end
          if res == 0 then
            pid = `cat #{config.full_pid_path}`.to_i
            puts "Splash Daemon Started, with PID : #{pid}"
            return {:case => :quiet_exit}
          else
            return {:case => :unknown_error, :more => "Splash Daemon loading error"}
          end

        else
          return {:case => :already_exist, :more => "Pid File, please verify if Splash daemon is running."}
        end
      end

      def stopdaemon(options = {})
          config = get_config
          if File.exist?(config.full_pid_path) then
            begin
              pid = `cat #{config.full_pid_path}`.to_i
              Process.kill("TERM", pid)
              acase = {:case => :quiet_exit, :more => 'Splash stopped succesfully'}
            rescue Errno::ESRCH
              acase =  {:case => :not_found, :more => "Process of PID : #{pid} not found"}
            end
            FileUtils::rm config.full_pid_path if File::exist? config.full_pid_path
          else
            acase =  {:case => :not_found, :more => "Splash is not running"}
          end
          return acase
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
          return {:case => :status_ok }
        elsif pid.empty? then
          return {:case => :status_ko, :more => "PID File error, you have to kill process manualy, with : '(sudo )kill -TERM #{realpid}'"}
        elsif realpid.empty? then
          return {:case => :status_ko, :more => "Process Splash Dameon missing, run 'splash daemon stop' to reload properly"}
        end
      end

    end
  end
end
