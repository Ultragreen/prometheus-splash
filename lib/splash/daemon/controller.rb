# coding: utf-8
require 'splash/daemon/orchestrator'

# base Splash module
module Splash

  # global daemon module
  module Daemon

    # Daemon Controller Module
    module Controller
      include Splash::Constants
      include Splash::Helpers
      include Splash::Config
      include Splash::Exiter
      include Splash::Loggers
      include Splash::Daemon::Orchestrator

      # Start the Splash Daemon
      # @param [Hash] options
      # @option options [Symbol] :quiet activate quiet mode for log (limit to :fatal)
      # @option options [Symbol] :foreground run daemon in foreground
      # @option options [Symbol] :purge clean input queue for daemon on configured transport
      # @return [Hash] Exiter Case (:quiet_exit, :already_exist, :unknown_error or other)
      def startdaemon(options = {})
        config = get_config
        log = get_logger
        log.level = :fatal if options[:quiet]
        unless verify_service url: config.prometheus_pushgateway_url then
          return {:case => :service_dependence_missing, :more => 'Prometheus Gateway'}
        end
        realpid = get_processes pattern: get_config.daemon_process_name
        foreground  = get_processes patterns: [ "splash", "foreground" ]
        unless foreground.empty? or options[:foreground] then
          return {:case => :already_exist, :more => "Splash Process already launched on foreground "}
        end

        unless File::exist? config.daemon_full_pid_path then
          unless realpid.empty? then
            return {:case => :already_exist, :more => "Splash Process already launched "}
          end
          if options[:purge] then
            transport = get_default_client
            if transport.class == Hash  and transport.include? :case then
              splash_exit transport
            else
              queue = "splash.#{Socket.gethostname}.input"
              transport.purge queue: queue
              log.info "Queue : #{queue} purged"
            end
          end
          daemon_config = {:description => config.daemon_process_name,
              :pid_file => config.daemon_full_pid_path,
              :stdout_trace => config.daemon_full_stdout_trace_path,
              :stderr_trace => config.daemon_full_stderr_trace_path,
              :foreground => options[:foreground]
            }

          ["int","term","hup"].each do |type| daemon_config["sig#{type}_handler".to_sym] = Proc::new {  ObjectSpace.each_object(Splash::Daemon::Orchestrator::Scheduler).first.terminate } end
          res = daemonize daemon_config do
              Scheduler::new options
          end
          sleep 1
          if res == 0 then
            pid = `cat #{config.daemon_full_pid_path}`.to_i
            log.ok "Splash Daemon Started, with PID : #{pid}"
            return {:case => :quiet_exit, :more => "Splash Daemon successfully loaded."}
          else
            return {:case => :unknown_error, :more => "Splash Daemon loading error, see logs for more details."}
          end

        else
          return {:case => :already_exist, :more => "Pid File, please verify if Splash daemon is running."}
        end
      end

      # Stop the Splash Daemon
      # @param [Hash] options
      # @option options [Symbol] :quiet activate quiet mode for log (limit to :fatal)
      # @return [Hash] Exiter Case (:quiet_exit, :not_found, other)
      def stopdaemon(options = {})
          config = get_config
          log = get_logger
          log.level = :fatal if options[:quiet]
          if File.exist?(config.daemon_full_pid_path) then
            begin
              pid = `cat #{config.daemon_full_pid_path}`.to_i
              Process.kill("TERM", pid)
              acase = {:case => :quiet_exit, :more => 'Splash stopped succesfully'}
            rescue Errno::ESRCH
              acase =  {:case => :not_found, :more => "Process of PID : #{pid} not found"}
            end
            FileUtils::rm config.daemon_full_pid_path if File::exist? config.daemon_full_pid_path
          else
            acase =  {:case => :not_found, :more => "Splash is not running"}
          end
          return acase
      end

      # Status of the Splash Daemon, display status
      # @param [Hash] options ignored
      # @return [Hash] Exiter Case (:status_ko, :status_ok)
      def statusdaemon(options = {})
        log = get_logger
        config = get_config
        pid = realpid = ''
        pid = `cat #{config.daemon_full_pid_path}`.to_s if File.exist?(config.daemon_full_pid_path)
        listpid = get_processes({ :pattern => get_config.daemon_process_name})
        pid.chomp!
        if listpid.empty? then
          realpid = ''
        else
          realpid = listpid.first
        end
        unless realpid.empty? then
          log.item "Splash Process is running with PID #{realpid} "
        else
          log.item 'Splash Process not found '
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
          return {:case => :status_ko, :more => "Process Splash Dameon missing, run 'splash daemon stop' to reload properly"}
        end
      end

    end
  end
end
