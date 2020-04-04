require 'open3'
require 'date'


module Splash
  class CommandWrapper
    include Splash::Templates

    include Splash::Config
    def initialize(name)
      @config  = get_config
      @name = name
      unless @config.commands.keys.include? @name.to_sym then
        $stderr.puts "Splash : command #{@name} is not defined in configuration"
        exit 40
      end
    end

    def ack
      puts "Sending ack for command : '#{@name}'"
      notify(0)
      exit 0
    end

    def notify(value)
      unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
        $stderr.puts "Prometheus PushGateway Service IS NOT running"
        $stderr.puts "Exit without notification."
        exit 30
      end
      registry = Prometheus::Client.registry
      url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}"
      metric = Prometheus::Client::Gauge.new(:errorcode, docstring: 'SPLASH metric batch errorcode')
      registry.register(metric)
      metric.set(value)
      Prometheus::Client::Push.new(@name, nil, url).add(registry)
      puts "Prometheus Gateway notified."
    end


    def call_and_notify(options)
      puts "Executing command : '#{@name}' "
      unless options[:trace] then
        puts "Traceless execution"
        system("#{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
        exit_code = $?.exitstatus
      else
        puts "Tracefull execution"
        stdout, stderr, status = Open3.capture3(@config.commands[@name.to_sym][:command])
        data = Hash::new
        data['date'] = DateTime.now.to_s
        data['cmd_name'] = @name
        data['cmd_line'] = @config.commands[@name.to_sym][:command]
        data['desc'] = @config.commands[@name.to_sym][:desc]
        data['error_code'] = status
        data['stdout'] = stdout
        data['stderr'] = stderr
        tp = Template::new(
            list_token: ["DATE","CMD_NAME","CMD_LINE","STDOUT","STDERR","DESC","DATE","ERROR_CODE"],
            template_file: @config.execution_template)
        tp.map data
        puts tp.output
      end

      exit_code = $?.exitstatus
      notify(exit_code)
      exit exit_code
    end
  end
end
