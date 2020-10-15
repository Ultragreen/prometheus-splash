# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for splashd daemon management
  class CLIController < Thor
    include Splash::Daemon::Controller
    include Splash::Transports
    include Splash::Exiter
    include Splash::Loggers


    # Thor method : starting Splashd
    option :foreground, :type => :boolean,  :aliases => "-F"
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

    # Thor method : purge transport input queue of Splashd daemon
    desc "purge", "Purge Transport Input queue of Daemon"
    def purge
      log = get_logger
      log.level = :fatal if options[:quiet]
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

    # Thor method : stopping Splashd
    desc "stop", "Stopping Splash Daemon"
    def stop
      acase = run_as_root :stopdaemon
      splash_exit acase
    end

    # Thor method : getting execution status of Splashd
    desc "status", "Splash Daemon status"
    def status
      acase = run_as_root :statusdaemon
      splash_exit acase
    end

    # Thor method : sending ping verb over transport in the input queue of Splashd
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
        splash_exit status: :error, case: :interrupt, more: "ping Command"
      end
    end

    # Thor method : sending get_jobs verb over transport in the input queue of Splashd
    desc "getjobs", "send a get_jobs verb to HOSTNAME daemon over transport (need an active tranport), Typicallly RabbitMQ"
    def getjobs(hostname=Socket.gethostname)
      log = get_logger
      log.info "ctrl+c for interrupt"
      begin
        transport = get_default_client
        if transport.class == Hash  and transport.include? :case then
          splash_exit transport
        else
          log.receive transport.execute({ :verb => :get_jobs,
                                  :return_to => "splash.#{Socket.gethostname}.returncli",
                                  :queue => "splash.#{hostname}.input" })
          splash_exit case: :quiet_exit
        end
      rescue Interrupt
        splash_exit status: :error, case: :interrupt, more: "getjobs Command"
      end
    end

    # Thor method : sending reset verb over transport in the input queue of Splashd
    desc "getjobs", "send a reset verb to HOSTNAME daemon over transport (need an active tranport), Typicallly RabbitMQ"
    def reset(hostname=Socket.gethostname)
      log = get_logger
      log.info "ctrl+c for interrupt"
      begin
        transport = get_default_client
        if transport.class == Hash  and transport.include? :case then
          splash_exit transport
        else
          log.receive transport.execute({ :verb => :reset,
                                  :return_to => "splash.#{Socket.gethostname}.returncli",
                                  :queue => "splash.#{hostname}.input" })
          splash_exit case: :quiet_exit
        end
      rescue Interrupt
        splash_exit status: :error, case: :interrupt, more: "reset Command"
      end
    end

  end

end
