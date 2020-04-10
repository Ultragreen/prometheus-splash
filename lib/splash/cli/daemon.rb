# coding: utf-8
module CLISplash

  class CLIController < Thor
    include Splash::LogsMonitor::DaemonController
    include Splash::Transports

    option :foreground, :type => :boolean
    desc "start", "Starting Logs Monitor Daemon"
    def start
      errorcode = run_as_root :startdaemon
      exit errorcode
    end

    desc "stop", "Stopping Logs Monitor Daemon"
    def stop
      errorcode = run_as_root :stopdaemon
      exit errorcode
    end

    desc "status", "Logs Monitor Daemon status"
    def status
      errorcode = run_as_root :statusdaemon
      exit errorcode
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
      rescue Interrupt
        puts "Splash : ping : Interrupted by user. "
        exit 33
      end
    end

  end

end
