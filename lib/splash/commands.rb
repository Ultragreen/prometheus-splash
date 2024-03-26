# coding: utf-8

# base Splash module
module Splash

  # Splash Commands module/namespace
  module Commands


    class CmdNotifier

      @@registry = Prometheus::Client::Registry::new
      @@metric_exitcode = Prometheus::Client::Gauge.new(:exitcode, docstring: 'SPLASH metric batch exitcode')
      @@metric_time = Prometheus::Client::Gauge.new(:exectime, docstring: 'SPLASH metric batch execution time')
      @@registry.register(@@metric_exitcode)
      @@registry.register(@@metric_time)



      def initialize(options={})
        @config = get_config
        @url = @config.prometheus_pushgateway_url
        @name = "cmd_#{options[:name].to_s}"
        @exitcode = options[:exitcode]
        @time = options[:time]
      end

      # send metrics to Prometheus PushGateway
      # @return [Bool]
      def notify
        unless verify_service url: @url then
          return { :case => :service_dependence_missing, :more => "Prometheus Notification not send."}
        end
        @@metric_exitcode.set(@exitcode)
        @@metric_time.set(@time)
        hostname = Socket.gethostname
        return Prometheus::Client::Push.new(job: @name, grouping_key: { instance: hostname}, gateway: @url).add(@@registry)
      end

    end


    class CmdRecords
      include Splash::Backends
      include Splash::Constants
      def initialize(name)
        @name = name
        @backend = get_backend :execution_trace
      end


      def clear
        @backend.del({:key => @name}) if  @backend.exist?({key: @name})
      end

      def purge(retention)
        retention = {} if retention.nil?
        if retention.include? :hours then
          adjusted_datetime = DateTime.now - retention[:hours].to_f / 24
        elsif retention.include? :hours then
          adjusted_datetime = DateTime.now - retention[:days].to_i
        else
          adjusted_datetime = DateTime.now - DEFAULT_RETENTION
        end

        data = get_all_records

        data.delete_if { |item|
          DateTime.parse(item.keys.first) <= (adjusted_datetime)}
        @backend.put key: @name, value: data.to_yaml
      end

      def add_record(record)
        data = get_all_records
        data.push({ DateTime.now.to_s => record })
        @backend.put key: @name, value: data.to_yaml
      end

      def get_all_records(options={})
        return (@backend.exist?({key: @name}))? YAML::load(@backend.get({key: @name})) : []
      end

    end


    # command execution wrapper
    class CommandWrapper
      include Splash::Templates
      include Splash::Config
      include Splash::Helpers
      include Splash::Backends
      include Splash::Exiter
      include Splash::Transports




      # Constructor
      # @param [String] name the name of the command
      def initialize(name)
        @config  = get_config
        @url = @config.prometheus_pushgateway_url
        @name = name
        unless @config.commands.select{|cmd| cmd[:name] == @name.to_sym }.count > 0 then
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
      def notify(value,time, session)
        log = get_logger
        unless verify_service url: @config.prometheus_pushgateway_url then
          return { :case => :service_dependence_missing, :more => "Prometheus Notification not send."}
        end
        cmdmonitor = CmdNotifier::new({name: @name, exitcode: value, time: time})
        if cmdmonitor.notify then
          log.ok "Sending metrics to Prometheus Pushgateway",session
        else
          log.ko "Failed to send metrics to Prometheus Pushgateway",session
        end
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
        command = @config.commands.select{|command| command[:name] == @name.to_sym}.first
        if command[:delegate_to] then
          return { :case => :options_incompatibility, :more => '--hostname forbidden with delagate commands'} if options[:hostname]
          log.send "Remote command : #{@name} execution delegate to : #{command[:delegate_to][:host]} as : #{command[:delegate_to][:remote_command]}", session
          log.warn "Local command : #{command[:command]} defined but ignored, because delegate have the priority"
          begin
            transport = get_default_client
            if transport.class == Hash  and transport.include? :case then
              return transport
            else
              res = transport.execute({ :verb => :execute_command,
                payload: {:name => command[:delegate_to][:remote_command].to_s},
                :return_to => "splash.#{Socket.gethostname}.return",
                :queue => "splash.#{command[:delegate_to][:host]}.input" })
              exit_code = res[:exit_code]
              log.receive "return with exitcode #{exit_code}", session

            end
          rescue Interrupt
            splash_exit case: :interrupt, more: "Remote command exection"
          end
        else
          log.info "Executing command : '#{@name}' ", session
          start = Time.now
          start_date = DateTime.now.to_s
          unless options[:trace] then
            log.item "Traceless execution", session
            if command[:user] then
              log.item "Execute with user : #{command[:user]}.", session
              system("sudo -u #{command[:user]} #{command[:command]} > /dev/null 2>&1")
            else
              system("#{command[:command]} > /dev/null 2>&1")
            end
            time = Time.now - start
            exit_code = $?.exitstatus
          else
            log.item "Tracefull execution", session
            if command[:user] then
              log.item "Execute with user : #{command[:user]}.", session
              stdout, stderr, status = Open3.capture3("sudo -u #{command[:user]} #{command[:command]}")
            else
              stdout, stderr, status = Open3.capture3(command[:command])
            end
            time = Time.now - start
            data = Hash::new
            data[:start_date] = start_date
            data[:end_date] = DateTime.now.to_s
            data[:cmd_name] = @name
            data[:cmd_line] = command[:command]
            data[:desc] = command[:desc]
            data[:status] = status.to_s
            data[:stdout] = stdout
            data[:stderr] = stderr
            data[:exec_time] = time.to_s
            cmdrec = CmdRecords::new @name
            cmdrec.purge(command[:retention])
            cmdrec.add_record data
            exit_code = status.exitstatus
          end
          log.ok "Command executed", session
          log.arrow "exitcode #{exit_code}", session
          if options[:notify] then
            acase = notify(exit_code,time.to_i,session)
          else
            log.item "Without Prometheus notification", session
          end
        end
        if options[:callback] then
          on_failure = (command[:on_failure])? command[:on_failure] : false
          on_success = (command[:on_success])? command[:on_success] : false
          if on_failure and exit_code > 0 then
            log.item "On failure callback : #{on_failure}", session
            if @config.commands.select {|item| item[:name] == on_failure}.count > 0 then
              @name = on_failure.to_s
              call_and_notify options
            else
              log.error "on_failure call error : #{on_failure.to_s} command inexistant.", session
              acase = { :case => :configuration_error , :more => "Command #{command[:name]} callback coniguration error"}
            end
          end
          if on_success and exit_code == 0 then
            log.item "On success callback : #{on_success}", session
            if @config.commands.select {|item| item[:name] == on_success}.count > 0 then
              @name = on_success.to_s
              call_and_notify options
            else
              log.error "on_success call error : #{on_success.to_s} command inexistant."
              acase = { :case => :configuration_error , :more => "Command #{command[:name]} callback coniguration error"}
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
