# coding: utf-8

# base Splash module
module Splash

  # Splash Commands module/namespace
  module Commands

    # command execution wrapper
    class CommandWrapper
      include Splash::Templates
      include Splash::Config
      include Splash::Helpers
      include Splash::Backends
      include Splash::Exiter
      include Splash::Transports


      @@registry = Prometheus::Client::Registry::new
      @@metric_exitcode = Prometheus::Client::Gauge.new(:errorcode, docstring: 'SPLASH metric batch errorcode')
      @@metric_time = Prometheus::Client::Gauge.new(:exectime, docstring: 'SPLASH metric batch execution time')
      @@registry.register(@@metric_exitcode)
      @@registry.register(@@metric_time)

      # Constructor
      # @param [String] name the name of the command
      def initialize(name)
        @config  = get_config
        @url = "http://#{@config.prometheus_pushgateway_host}:#{@config.prometheus_pushgateway_port}/#{@config.prometheus_pushgateway_path}"
        @name = name
        unless @config.commands.keys.include? @name.to_sym then
          splash_exit case: :not_found, more: "command #{@name} is not defined in configuration"
        end
      end

      # wrapper for ack command ( return 0 to prometheus via notify)
      def ack
        get_logger.info "Sending ack for command : '#{@name}'"
        notify(0,0)
      end

      # send metrics to Prometheus PushGateway
      # @param [String] value numeric.to_s
      # @param [String] time execution time numeric.to_s
      # @return [Hash] Exiter case :quiet_exit
      def notify(value,time)
        unless verify_service host: @config.prometheus_pushgateway_host ,port: @config.prometheus_pushgateway_port then
          return { :case => :service_dependence_missing, :more => "Prometheus Notification not send."}
        end
        @@metric_exitcode.set(value)
        @@metric_time.set(time)
        hostname = Socket.gethostname
        Prometheus::Client::Push.new(@name, hostname, @url).add(@@registry)
        return { :case => :quiet_exit}
      end

      # execute commands or sequence via callbacks, remote or not, notify prometheus, templatize report to backends
      # the big cheese
      # @param [Hash] options
      # @option options [String] :session a number of session in case of Daemon Logger
      # @option options [String] :hostname for remote execution (can't be use with commands with delegate_to)
      # @option options [Boolean] :notify to activate prometheus notifications
      # @option options [Boolean] :trace to activate execution report
      # @option options [Boolean] :callback to activate sequence and callbacks executions
      # @return [Hash] Exiter case
      def call_and_notify(options)
        log = get_logger
        session = (options[:session])? options[:session] : get_session
        acase = { :case => :quiet_exit }
        exit_code = 0
        if @config.commands[@name.to_sym][:delegate_to] then
          return { :case => :options_incompatibility, :more => '--hostname forbidden with delagate commands'} if options[:hostname]
          log.send "Remote command : #{@name} execution delegate to : #{@config.commands[@name.to_sym][:delegate_to][:host]} as : #{@config.commands[@name.to_sym][:delegate_to][:remote_command]}", session
          begin
            transport = get_default_client
            if transport.class == Hash  and transport.include? :case then
              return transport
            else
              res = transport.execute({ :verb => :execute_command,
                payload: {:name => @config.commands[@name.to_sym][:delegate_to][:remote_command].to_s},
                :return_to => "splash.#{Socket.gethostname}.return",
                :queue => "splash.#{@config.commands[@name.to_sym][:delegate_to][:host]}.input" })
              exit_code = res[:exit_code]
              log.receive "return with exitcode #{exit_code}", session

            end
          end
        else
          log.info "Executing command : '#{@name}' ", session
          start = Time.now
          start_date = DateTime.now.to_s
          unless options[:trace] then
            log.item "Traceless execution", session
            if @config.commands[@name.to_sym][:user] then
              log.item "Execute with user : #{@config.commands[@name.to_sym][:user]}.", session
              system("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
            else
              system("#{@config.commands[@name.to_sym][:command]} > /dev/null 2>&1")
            end
            time = Time.now - start
            exit_code = $?.exitstatus
          else
            log.item "Tracefull execution", session
            if @config.commands[@name.to_sym][:user] then
              log.item "Execute with user : #{@config.commands[@name.to_sym][:user]}.", session
              stdout, stderr, status = Open3.capture3("sudo -u #{@config.commands[@name.to_sym][:user]} #{@config.commands[@name.to_sym][:command]}")
            else
              stdout, stderr, status = Open3.capture3(@config.commands[@name.to_sym][:command])
            end
            time = Time.now - start
            tp = Template::new(
              list_token: @config.execution_template_tokens,
              template_file: @config.execution_template_path)
            data = Hash::new
            data[:start_date] = start_date
            data[:end_date] = DateTime.now.to_s
            data[:cmd_name] = @name
            data[:cmd_line] = @config.commands[@name.to_sym][:command]
            data[:desc] = @config.commands[@name.to_sym][:desc]
            data[:status] = status.to_s
            data[:stdout] = stdout
            data[:stderr] = stderr
            data[:exec_time] = time.to_s
            backend = get_backend :execution_trace
            key = @name

            backend.put key: key, value: data.to_yaml
            exit_code = status.exitstatus
          end
          log.ok "Command executed", session
          log.arrow "exitcode #{exit_code}", session
          if options[:notify] then
            acase = notify(exit_code,time.to_i)
            get_logger.ok "Prometheus Gateway notified.",session
          else
            log.item "Without Prometheus notification", session
          end
        end

        if options[:callback] then
          on_failure = (@config.commands[@name.to_sym][:on_failure])? @config.commands[@name.to_sym][:on_failure] : false
          on_success = (@config.commands[@name.to_sym][:on_success])? @config.commands[@name.to_sym][:on_success] : false
          if on_failure and exit_code > 0 then
            log.item "On failure callback : #{on_failure}", session
            if @config.commands.keys.include?  on_failure then
              @name = on_failure.to_s
              call_and_notify options
            else
              acase = { :case => :configuration_error , :more => "on_failure call error : #{on_failure} command inexistant."}
            end
          end
          if on_success and exit_code == 0 then
            log.item "On success callback : #{on_success}", session
            if @config.commands.keys.include?  on_success then
              @name = on_success.to_s
              call_and_notify options
            else
              acase = { :case => :configuration_error , :more => "on_success call error : #{on_failure} command inexistant."}
            end
          end
        else
          log.item "Without callbacks sequences", session
        end
        acase[:exit_code] = exit_code
        return acase
      end
    end
  end
end
