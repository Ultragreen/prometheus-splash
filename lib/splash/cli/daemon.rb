# coding: utf-8
module CLISplash

  class CLIController < Thor
    include Splash::LogsMonitor::DaemonController
    include Splash::Transports

    option :foreground, :type => :boolean
    desc "start", "Starting Logs Monitor Daemon"
    def start
      acase = run_as_root :startdaemon
      splash_exit acase
    end

    desc "stop", "Stopping Logs Monitor Daemon"
    def stop
      acase = run_as_root :stopdaemon
      splash_exit acase
    end

    desc "status", "Logs Monitor Daemon status"
    def status
      acase = run_as_root :statusdaemon
      splash_exit acase
    end

    desc "ping HOSTNAME", "send a ping to HOSTNAME daemon over transport (need an active tranport), Typicallly RabbitMQ"
    def ping(hostname=Socket.gethostname)
      puts "ctrl+c for interrupt"
      queue = "splash.#{Socket.gethostname}.returncli"
      order = {:verb => :ping, :payload => {:hostname => Socket.gethostname}, :return_to => queue}

      lock = Mutex.new
      condition = ConditionVariable.new
      begin
        get_default_subscriber(queue: queue).subscribe(timeout: 10) do |delivery_info, properties, payload|
          puts YAML::load(payload)
          lock.synchronize { condition.signal }
        end
        get_default_client.publish queue: "splash.#{hostname}.input", message: order.to_yaml
        lock.synchronize { condition.wait(lock) }
        splash_exit case: :quiet_exit
      rescue Interrupt
        splash_exit status: :error, case: :interrupt, more: "Ping Command"
      end
    end

  end

end
