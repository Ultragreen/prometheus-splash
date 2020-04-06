require 'open3'
require 'date'
require 'socket'

module Splash
  class CommandWrapper
    include Splash::Templates
    include Splash::Config
    include Splash::Helpers
    include Splash::Backends

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
      hostname = Socket.gethostname
      Prometheus::Client::Push.new(@name, hostname, url).add(registry)
      puts "Prometheus Gateway notified."
    end


    def call_and_notify(options)
      puts "Executing command : '#{@name}' "
      unless options[:trace] then
        puts "Traceless execution"
        if @config.commands[@name.to_sym][:user] then
          puts "Execute with user : #{@config.commands[@name.to_sym][:user]}."
          system("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
        else
          system("#{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
        end
        exit_code = $?.exitstatus
      else
        puts "Tracefull execution"
        if @config.commands[@name.to_sym][:user] then
          puts "Execute with user : #{@config.commands[@name.to_sym][:user]}."
          stdout, stderr, status = Open3.capture3("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]}")
        else
          stdout, stderr, status = Open3.capture3(@config.commands[@name.to_sym][:command])
        end
        tp = Template::new(
            list_token: @config.execution_template_tokens,
            template_file: @config.execution_template_path)

        tp.date = DateTime.now.to_s
        tp.cmd_name = @name
        tp.cmd_line = @config.commands[@name.to_sym][:command]
        tp.desc = @config.commands[@name.to_sym][:desc]
        tp.status = status.to_s
        tp.stdout = stdout
        tp.stderr = stderr
        backend = get_default_backend
        key = "#{@name}_trace.last"
        backend.put key: key, value: tp.output
        exit_code = status.exitstatus
      end

      notify(exit_code)
      exit exit_code
    end
  end
end
