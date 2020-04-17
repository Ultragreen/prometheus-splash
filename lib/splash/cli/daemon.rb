# coding: utf-8
module CLISplash

  class CLIController < Thor
    include Splash::LogsMonitor::DaemonController
    include Splash::Transports
    include Splash::Exiter
    include Splash::Loggers


    option :foreground, :type => :boolean
    option :purge, :type => :boolean, default: true
    option :scheduling, :type => :boolean, default: true
    long_desc <<-LONGDESC
    Starting Splash Daemon\n
    With --foreground, run Splash in foreground\n
    With --no-scheduling, inhibit commands scheduling\n
    With --no-purge, inhibit purge Input Queue for Splash Daemon
    LONGDESC
    desc "start", "Starting Splash Daemon"
    def start
      acase = run_as_root :startdaemon, options
      splash_exit acase
    end


    desc "purge", "Purge Transport Input queue of Daemon"
    def purge
      log = get_logger
      transport = get_default_client
      if transport.class == Hash  and transport.include? :case then
        splash_exit transport
      else
        queue = "splash.#{Socket.gethostname}.input"
        transport.purge queue: queue
        log.ok "Queue : #{queue} purged"
        splash_exit case: :quiet_exit
      end
    end

    desc "stop", "Stopping Splash Daemon"
    def stop
      acase = run_as_root :stopdaemon
      splash_exit acase
    end

    desc "status", "Splash Daemon status"
    def status
      acase = run_as_root :statusdaemon
      splash_exit acase
    end

    desc "ping HOSTNAME", "send a ping to HOSTNAME daemon over transport (need an active tranport), Typicallly RabbitMQ"
    def ping(hostname=Socket.gethostname)
      log = get_logger
      log.info "ctrl+c for interrupt"
      begin
        transport = get_default_client
        if transport.class == Hash  and transport.include? :case then
          splash_exit transport
        else
          log.receive transport.execute({ :verb => :ping,
                                  :payload => {:hostname => Socket.gethostname},
                                  :return_to => "splash.#{Socket.gethostname}.returncli",
                                  :queue => "splash.#{hostname}.input" })
          splash_exit case: :quiet_exit
        end
      rescue Interrupt
        splash_exit status: :error, case: :interrupt, more: "Ping Command"
      end
    end

  end

end
