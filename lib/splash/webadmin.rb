# coding: utf-8



# base Splash module
module Splash

  # global daemon module
  module WebAdmin

    # Daemon Controller Module
    module Controller
      include Splash::Constants
      include Splash::Helpers
      include Splash::Config
      include Splash::Exiter
      include Splash::Loggers


      # Start the Splash Daemon
      # @param [Hash] options
      # @option options [Symbol] :quiet activate quiet mode for log (limit to :fatal)
      # @return [Hash] Exiter Case (:quiet_exit, :already_exist, :unknown_error or other)
      def startdaemon(options = {})
        require 'splash/webadmin/main'
        config = get_config
        log = get_logger
        log.level = :fatal if options[:quiet]
        realpid = get_processes pattern: get_config.webadmin_process_name


        unless File::exist? config.webadmin_full_pid_path then
          unless realpid.empty? then
            return {:case => :already_exist, :more => "Splash WebAdmin Process already launched "}
          end

          daemon_config = {:description => config.webadmin_process_name,
              :pid_file => config.webadmin_full_pid_path,
              :stdout_trace => config.webadmin_full_stdout_trace_path,
              :stderr_trace => config.webadmin_full_stderr_trace_path
            }

          ["int","term","hup"].each do |type| daemon_config["sig#{type}_handler".to_sym] = Proc::new {  WebAdminApp.quit! } end
          res = daemonize daemon_config do
            log = get_logger logger: :web, force: true
            log.info "Starting Splash WebAdmin"
            WebAdminApp.run!
          end
          sleep 1
          if res == 0 then
            pid = `cat #{config.webadmin_full_pid_path}`.to_i
            log.ok "Splash WebAdmin Started, with PID : #{pid}"
            return {:case => :quiet_exit, :more => "Splash WebAdmin successfully loaded."}
          else
            return {:case => :unknown_error, :more => "Splash WebAdmin loading error, see logs for more details."}
          end

        else
          return {:case => :already_exist, :more => "Pid File, please verify if Splash WebAdmin is running."}
        end
      end

      # Stop the Splash WebAdmin
      # @param [Hash] options
      # @option options [Symbol] :quiet activate quiet mode for log (limit to :fatal)
      # @return [Hash] Exiter Case (:quiet_exit, :not_found, other)
      def stopdaemon(options = {})
          config = get_config
          log = get_logger
          log.level = :fatal if options[:quiet]
          if File.exist?(config.webadmin_full_pid_path) then
            begin
              pid = `cat #{config.webadmin_full_pid_path}`.to_i
              Process.kill("TERM", pid)
              acase = {:case => :quiet_exit, :more => 'Splash WebAdmin stopped succesfully'}
            rescue Errno::ESRCH
              acase =  {:case => :not_found, :more => "Process of PID : #{pid} not found"}
            end
            FileUtils::rm config.webadmin_full_pid_path if File::exist? config.webadmin_full_pid_path
          else
            acase =  {:case => :not_found, :more => "Splash WebAdmin is not running"}
          end
          return acase
      end

      # Status of the Splash WebAdmin, display status
      # @param [Hash] options ignored
      # @return [Hash] Exiter Case (:status_ko, :status_ok)
      def statusdaemon(options = {})
        log = get_logger
        config = get_config
        pid = realpid = ''
        pid = `cat #{config.webadmin_full_pid_path}`.to_s if File.exist?(config.webadmin_full_pid_path)
        listpid = get_processes({ :pattern => get_config.webadmin_process_name})
        pid.chomp!
        if listpid.empty? then
          realpid = ''
        else
          realpid = listpid.first
        end
        unless realpid.empty? then
          log.item "Splash  WebAdmin Process is running with PID #{realpid} "
        else
          log.item 'Splash  WebAdminProcess not found '
        end
        unless pid.empty? then
          log.item "and PID file exist with PID #{pid}"
        else
          log.item "and PID file don't exist"
        end
        if pid == realpid then
          return {:case => :status_ok }
        elsif pid.empty? then
          return {:case => :status_ko, :more => "PID File error, you have to kill process manualy, with : '(sudo )kill -TERM #{realpid}'"}
        elsif realpid.empty? then
          return {:case => :status_ko, :more => "Process Splash WebAdmin missing, run 'splash webadmin stop' before reload properly"}
        end
      end

    end
  end
end
