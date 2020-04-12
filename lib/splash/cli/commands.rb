# coding: utf-8
module CLISplash


  class Commands < Thor
    include Splash::Config
    include Splash::Backends
    include Splash::Exiter
    include Splash::Transports
    include Splash::Templates

    desc "execute NAME", "run for command/sequence or ack result"
    long_desc <<-LONGDESC
    execute command or sequence or ack result\n
    with --no-trace prevent storing execution trace in configured backend (see config file)\n
    with --ack, notify errorcode=0 to Prometheus PushGateway\n
    with --no-notify, bypass Prometheus notification\n
    with --no-callback, never execute callback (:on_failure, :on_success)\n
                        never follow sequences\n
    with --hostname, execute on an other Splash daemon node
    LONGDESC
    option :trace, :type => :boolean, :default => true
    option :ack, :type => :boolean, negate: false
    option :notify, :type => :boolean, :default => true
    option :callback, :type => :boolean, :default => true
    option :hostname, :type => :string
    def execute(name)
      if is_root? then
        if options[:hostname] then
          splash_exit({ :case => :options_incompatibility, :more => '--hostname forbidden with delagate commands'}) if get_config.commands[name.to_sym][:delegate_to]
          puts "Remote Splash configured commands on #{options[:hostname]}:"
          puts "ctrl+c for interrupt"
          begin
            transport = get_default_client
            if transport.class == Hash  and transport.include? :case then
              splash_exit transport
            else
              if options[:ack] then
                res = transport.execute({ :verb => :ack_command,
                                      payload: {:name => name},
                                      :return_to => "splash.#{Socket.gethostname}.returncli",
                                      :queue => "splash.#{options[:hostname]}.input" })
                res[:more] = "Remote command : :ack_command OK"
                splash_exit res
              else
                res = transport.execute({ :verb => :execute_command,
                                    payload: {:name => name},
                                    :return_to => "splash.#{Socket.gethostname}.returncli",
                                    :queue => "splash.#{options[:hostname]}.input" })
                res[:more] = "Remote command : :execute_command Scheduled"
                splash_exit res
              end
            end
          rescue Interrupt
            splash_exit case: :interrupt, more: "Remote command exection"
          end
        else
          command =  Splash::CommandWrapper::new(name)
          if options[:ack] then
            splash_exit command.ack
          end
          acase = command.call_and_notify trace: options[:trace], notify: options[:notify], callback: options[:callback]
          splash_exit acase
        end
      else
        splash_exit case: :not_root, :more => "Command execution"
      end
    end


    desc "schedule NAME", "Schedule excution of command on Splash daemon"
    long_desc <<-LONGDESC
    Schedule excution of command on Splash daemon\n
    with --hostname, Schedule on an other Splash daemon via transport\n
    with --at TIME/DATE, Schedule at specified date/time, like 2030/12/12 23:30:00 or 12:00 \n
    with --in TIMING, Schedule in specified timing, like 12s, 1m, 2h, 3m10s, 10d\n
    --in and --at are imcompatibles.\n
    WARNING : scheduling by CLI are not percisted, so use it only for specifics cases.\n
    NOTES : Scheduling, force trace, notifying and callback.
    LONGDESC
    option :hostname, :type => :string
    option :at, :type => :string
    option :in, :type => :string
    def schedule(name)
      hostname = (options[:hostname])? options[:hostname] : Socket.gethostname
      splash_exit({ :case => :options_incompatibility, :more => '--at or --in is required'}) unless options[:at] or options[:in]
      splash_exit({ :case => :options_incompatibility, :more => '--at an --in'}) if options[:at] and options[:in]
      puts "Remote Splash scheduling command on #{hostname}:"
      puts "ctrl+c for interrupt"
      begin
        transport = get_default_client
        if transport.class == Hash  and transport.include? :case then
          splash_exit transport
        else
          schedule = { :in => options[:in]} if options[:in]
          schedule = { :at => options[:at]} if options[:at]
          res = transport.execute({ :verb => :execute_command,
                                  payload: {:name => name, :schedule => schedule},
                                  :return_to => "splash.#{Socket.gethostname}.returncli",
                                  :queue => "splash.#{hostname}.input" })
          res[:more] = "Remote command : :execute_command with schedule"
          splash_exit res
        end
      rescue Interrupt
        splash_exit case: :interrupt, more: "Remote command exection"
      end

    end


    desc "treeview", "Show commands sequence tree"
    def treeview(command, depht = 0)
      puts "Command : #{command.to_s}" if depht == 0
      cmd  = get_config.commands[command.to_sym]
      if cmd[:on_failure] then
        print " " * depht + " "
        puts "* on failure => #{cmd[:on_failure]}"
        treeview(cmd[:on_failure], depht+2)
      end
      if cmd[:on_success] then
        print " " * depht + " "
        puts "* on success => #{cmd[:on_success]}"
        treeview(cmd[:on_success],depht+2)
      end
      splash_exit case: :quiet_exit
    end


    desc "list", "Show configured commands"
    long_desc <<-LONGDESC
    Show configured commands\n
    with --detail, show command details\n
    with --hostname, ask other Splash daemon via transport\n
    LONGDESC
    option :detail, :type => :boolean
    option :hostname, :type => :string
    def list
      list = {}
      if options[:hostname] then
        puts "Remote Splash configured commands on #{options[:hostname]}:"
        puts "ctrl+c for interrupt"
        begin
          transport = get_default_client
          if transport.class == Hash  and transport.include? :case then
            splash_exit transport
          else
            list = transport.execute({ :verb => :list_commands,
                                  :return_to => "splash.#{Socket.gethostname}.returncli",
                                  :queue => "splash.#{options[:hostname]}.input" })
          end
        rescue Interrupt
          splash_exit case: :interrupt, more: "remote list Command"
        end
      else
        puts "Splash configured commands :"
        list = get_config.commands
      end
      puts 'No configured commands found' if list.keys.empty?
      list.keys.each do |command|
        puts " * #{command.to_s}"
        if options[:detail] then
          puts "   - command line : '#{list[command][:command]}'"
          puts "   - command description : '#{list[command][:desc]}'"
          puts "   - command failure callback : '#{list[command.to_sym][:on_failure]}'" if list[command.to_sym][:on_failure]
          puts "   - command success callback : '#{list[command.to_sym][:on_success]}'" if list[command.to_sym][:on_success]
          if list[command.to_sym][:schedule]
            sched,val = list[command.to_sym][:schedule].flatten
            puts "   - command scheduled : #{sched} #{val}."
          end
        end
      end
      splash_exit case: :quiet_exit
    end


    desc "show COMMAND", "Show specific configured command COMMAND"
    long_desc <<-LONGDESC
    Show specific configured command COMMAND\n
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)
    LONGDESC
    option :hostname, :type => :string
    def show(command)
      list = {}
      if options[:hostname] then
        puts "Remote Splash configured commands on #{options[:hostname]}:"
        puts "ctrl+c for interrupt"
        begin
          transport = get_default_client
          if transport.class == Hash  and transport.include? :case then
            splash_exit transport
          else
            list = transport.execute({ :verb => :list_commands,
                                  :return_to => "splash.#{Socket.gethostname}.returncli",
                                  :queue => "splash.#{options[:hostname]}.input" })
          end
        rescue Interrupt
          splash_exit case: :interrupt, more: "remote list Command"
        end
      else
        list = get_config.commands
      end
      if list.keys.include? command.to_sym then
        puts "Splash command : #{command}"
        puts "   - command line : '#{list[command.to_sym][:command]}'"
        puts "   - command description : '#{list[command.to_sym][:desc]}'"
        puts "   - command failure callback : '#{list[command.to_sym][:on_failure]}'" if list[command.to_sym][:on_failure]
        puts "   - command success callback : '#{list[command.to_sym][:on_success]}'" if list[command.to_sym][:on_success]
        if list[command.to_sym][:schedule]
          sched,val = list[command.to_sym][:schedule].flatten
          puts "   - command scheduled : #{sched} #{val}."
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => 'Command not configured'
      end
    end


    desc "lastrun COMMAND", "Show last running result for specific configured command COMMAND"
    long_desc <<-LONGDESC
    Show last running result for specific configured command COMMAND\n
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)
    LONGDESC
    option :hostname, :type => :string
    def lastrun(command)
      backend = get_backend :execution_trace
      redis = (backend.class == Splash::Backends::Redis)? true : false
      if not redis and options[:hostname] then
        splash_exit case: :specific_config_required, :more => "Redis backend is requiered for Remote execution report request"
      end
      list = get_config.commands.keys
      if options[:hostname] then
        list = backend.list("*", options[:hostname]).map(&:to_sym)
      end
      if list.include? command.to_sym then
        print "Splash command #{command} previous execution report:\n\n"
        req  = { :key => command}
        req[:hostname] = options[:hostname] if options[:hostname]
        if backend.exist? req then
          res = backend.get req
          tp = Template::new(
              list_token: get_config.execution_template_tokens,
              template_file: get_config.execution_template_path)
          tp.map YAML::load(res)
          print tp.output
        else
          puts "Command not already runned."
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => "Command report never runned remotly" if options[:hostname]
      end
    end

    desc "getreportlist", "list all executions report results "
    long_desc <<-LONGDESC
    list all executions report results\n
    with --pattern <SEARCH>, search type string, wilcard * (group) ? (char)\n
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)\n
    with --all, get all execution report for all servers (only with Redis backend configured)\n
    with --detail, get major informations of each reports\n
    --all and --hostname are exclusives
    LONGDESC
    option :pattern, :type => :string
    option :hostname, :type => :string
    option :all, :type => :boolean, :negate => false
    option :detail, :type => :boolean
    def getreportlist
      if options[:hostname] and options[:all] then
        splash_exit case: :options_incompatibility, more: "--all, --hostname"
      end
      backend = get_backend :execution_trace
      redis = (backend.class == Splash::Backends::Redis)? true : false
      if not redis and (options[:hostname] or options[:all]) then
        splash_exit case: :specific_config_required, more: "Redis Backend requiered for Remote execution report Request"
      end
      pattern = (options[:pattern])? options[:pattern] : '*'
      if options[:all] then
        res = backend.listall pattern
      elsif options[:hostname]
        res = backend.list pattern, options[:hostname]
      else
        res = backend.list pattern
      end
      print "List of Executions reports :\n\n"
      puts "Not reports found" if res.empty?
      res.each do |item|
        host = ""
        command = ""
        if options[:all]
          host,command = item.split('#')
          puts " * Command : #{command} @ host : #{host}"
        else
          command = item
          puts " * Command : #{command}"
        end
        if options[:detail] then
          req = { :key => command }
          req[:hostname] = host if options[:all]
          res = YAML::load(backend.get(req))
          puts "   - Status : #{res[:status]}"
          puts "   - Start date : #{res[:start_date]}"
          puts "   - End date : #{res[:end_date]}"
          puts "   - Execution time : #{res[:exec_time]}"
        end
      end
      splash_exit case: :quiet_exit
    end

  end
end
