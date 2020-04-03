module Splash
  class CommandWrapper
    def initialize(name)
      @name = name
    end

    def ack
      puts "Sending ack for command : '#{@name}'"
      notify(0)
      exit 0
    end

    def notify(value)
      registry = Prometheus::Client.registry
      metric = Prometheus::Client::Gauge.new(:errorcode, docstring: 'SPLASH metric batch errorcode')
      registry.register(metric)
      metric.set(value)
      Prometheus::Client::Push.new(@name).add(registry)
    end


    def call_and_notify
      puts "Executing command : '#{@name}' and notify Prometheus PushGateway"
      system("#{@name} > /dev/null")
      exit_code = $?.exitstatus
      notify(exit_code)
    end
  end
end
