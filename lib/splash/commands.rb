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
      @registry = Prometheus::Client.registry
      @url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}"
      @metric_exitcode = Prometheus::Client::Gauge.new(:errorcode, docstring: 'SPLASH metric batch errorcode')
      @metric_time = Prometheus::Client::Gauge.new(:exectime, docstring: 'SPLASH metric batch execution time')
      @registry.register(@metric_exitcode)
      @registry.register(@metric_time)
    end

    def ack
      puts "Sending ack for command : '#{@name}'"
      notify(0)
      exit 0
    end

    def notify(value,time)
      unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
        $stderr.puts "Prometheus PushGateway Service IS NOT running"
        $stderr.puts "Exit without notification."
        exit 30
      end
      @metric_exitcode.set(value)
      @metric_time.set(time)
      hostname = Socket.gethostname
      Prometheus::Client::Push.new(@name, hostname, @url).add(@registry)
      puts " * Prometheus Gateway notified."
    end


    def call_and_notify(options)
      puts "Executing command : '#{@name}' "
      start = Time.now
      start_date = DateTime.now.to_s
      unless options[:trace] then
        puts " * Traceless execution"
        if @config.commands[@name.to_sym][:user] then
          puts " * Execute with user : #{@config.commands[@name.to_sym][:user]}."
          system("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
        else
          system("#{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
        end
        time = Time.now - start
        exit_code = $?.exitstatus
      else
        puts " * Tracefull execution"
        if @config.commands[@name.to_sym][:user] then
          puts " * Execute with user : #{@config.commands[@name.to_sym][:user]}."
          stdout, stderr, status = Open3.capture3("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]}")
        else
          stdout, stderr, status = Open3.capture3(@config.commands[@name.to_sym][:command])
        end
        time = Time.now - start
        tp = Template::new(
            list_token: @config.execution_template_tokens,
            template_file: @config.execution_template_path)

        tp.start_date = start_date
        tp.end_date = DateTime.now.to_s
        tp.cmd_name = @name
        tp.cmd_line = @config.commands[@name.to_sym][:command]
        tp.desc = @config.commands[@name.to_sym][:desc]
        tp.status = status.to_s
        tp.stdout = stdout
        tp.stderr = stderr
        tp.exec_time = time.to_s
        backend = get_backend :execution_trace
        key = @name
        backend.put key: key, value: tp.output
        exit_code = status.exitstatus

      end

      puts "  => exitcode #{exit_code}"
      if options[:notify] then
        notify(exit_code,time.to_i)
      else
        puts " * Without Prometheus notification"
      end
      if options[:callback] then
        on_failure = (@config.commands[@name.to_sym][:on_failure])? @config.commands[@name.to_sym][:on_failure] : false
        on_success = (@config.commands[@name.to_sym][:on_success])? @config.commands[@name.to_sym][:on_success] : false

        if on_failure and exit_code > 0 then
          puts " * On failure callback : #{on_failure}"
          if @config.commands.keys.include?  on_failure then
            @name = on_failure.to_s
            call_and_notify options
          else
            $stderr.puts "on_failure call error : configuration mistake : #{on_failure} command inexistant."
          end
        end
        if on_success and exit_code == 0 then
          puts " * On success callback : #{on_success}"
          if @config.commands.keys.include?  on_success then
            @name = on_success.to_s
            call_and_notify options
          else
            $stderr.puts "on_success call error : configuration mistake : #{on_success} command inexistant."
          end
        end
      else
        puts " * Without callbacks sequences"
      end

      exit exit_code
    end
  end
end
