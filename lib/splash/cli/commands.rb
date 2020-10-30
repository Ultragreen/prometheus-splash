# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for commands management
  class Commands < Thor
    include Splash::Config
    include Splash::Backends
    include Splash::Exiter
    include Splash::Transports
    include Splash::Templates
    include Splash::Loggers
    include Splash::Commands


    # Thor method : execution of command
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
    option :ack, :type => :boolean, negate: false,  :aliases => "-a"
    option :notify, :type => :boolean, :default => true
    option :callback, :type => :boolean, :default => true
    option :hostname, :type => :string,  :aliases => "-H"
    def execute(name)
      log = get_logger
      log.level = :fatal if options[:quiet]
      if is_root? then
        if options[:hostname] then
          options[:hostname] = Socket.gethostname if options[:hostname] == 'hostname'
          splash_exit({ :case => :options_incompatibility, :more => '--hostname forbidden with delagate commands'}) if get_config.commands[name.to_sym][:delegate_to]
          log.info "Remote Splash configured commands on #{options[:hostname]}:"
          log.info "ctrl+c for interrupt"
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
              end
            end
          rescue Interrupt
            splash_exit case: :interrupt, more: "Remote command exection"
          end
          log.receive "Command execute confirmation"
          res[:more] = "Remote command : :execute_command Scheduled"
          splash_exit res
        else
          command =  CommandWrapper::new(name)
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


    # Thor method : scheduling commands
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
    option :hostname, :type => :string, :default => Socket.gethostname,  :aliases => "-H"
    option :at, :type => :string
    option :in, :type => :string
    def schedule(name)
      unless is_root? then
        splash_exit case: :not_root, :more => "Command scheduling"
      end
      log = get_logger
      log.level = :fatal if options[:quiet]
      hostname = (options[:hostname])? options[:hostname] : Socket.gethostname
      splash_exit({ :case => :options_incompatibility, :more => '--at or --in is required'}) unless options[:at] or options[:in]
      splash_exit({ :case => :options_incompatibility, :more => '--at an --in'}) if options[:at] and options[:in]
      log.info "Remote Splash scheduling command on #{hostname}:"
      log.info "ctrl+c for interrupt"
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
        end
      rescue Interrupt
        splash_exit case: :interrupt, more: "Remote command exection"
      end
      log.receive "Execute command sheduled confirmed"
      res[:more] = "Remote command : :execute_command with schedule"
      splash_exit res

    end

    # Thor method : getting a treeview of sequence of commands
    desc "treeview", "Show commands sequence tree"
    long_desc <<-LONGDESC
    Show commands sequence tree\n
    with --hostname, ask other Splash daemon via transport\n
    LONGDESC
    option :hostname, :type => :string,  :aliases => "-H"
    def treeview(command)
      unless is_root? then
        splash_exit case: :not_root, :more => "Command treeview"
      end
      depht = 0
      log  = get_logger
      if options[:hostname] then
        options[:hostname] = Socket.gethostname if options[:hostname] == 'hostname'
        log.info "Remote Splash treeview command on #{options[:hostname]}:"
        log.info "ctrl+c for interrupt"
        begin
          transport = get_default_client
          if transport.class == Hash  and transport.include? :case then
            splash_exit transport
          else
            commands = transport.execute({ :verb => :list_commands,
                                  :return_to => "splash.#{Socket.gethostname}.returncli",
                                  :queue => "splash.#{options[:hostname]}.input" })
          end
        rescue Interrupt
          splash_exit case: :interrupt, more: "Remote command exection"
        end
        log.receive "Receving list of commands from #{options[:hostname]}"
      else
        commands  = get_config.commands
      end
      log.info "Command : #{command.to_s}" if depht == 0
      aproc = Proc::new do |command,depht|
        cmd  = commands[command.to_sym]
        if cmd[:on_failure] then
          spacer=  " " * depht + " "
          log.flat "#{spacer}* on failure => #{cmd[:on_failure]}"
          aproc.call(cmd[:on_failure], depht+2)
        end
        if cmd[:on_success] then
          spacer = " " * depht + " "
          log.flat "#{spacer}* on success => #{cmd[:on_success]}"
          aproc.call(cmd[:on_success],depht+2)
        end
      end
      aproc.call(command,depht)
    end


    # Thor method : getting the list of available commands in splash config
    desc "list", "Show configured commands"
    long_desc <<-LONGDESC
    Show configured commands\n
    with --detail, show command details\n
    with --hostname, ask other Splash daemon via transport\n
    LONGDESC
    option :detail, :type => :boolean,  :aliases => "-D"
    option :hostname, :type => :string,  :aliases => "-H"
    def list
      unless is_root? then
        splash_exit case: :not_root, :more => "Command list"
      end
      log = get_logger
      list = {}
      if options[:hostname] then
        options[:hostname] = Socket.gethostname if options[:hostname] == 'hostname'
        log.info "Remote Splash configured commands on #{options[:hostname]}:"
        log.info  "ctrl+c for interrupt"
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
        log.receive "Receving list of commands from #{options[:hostname]}"
      else
        list = get_config.commands
      end
      log.info "Splash configured commands :"
      log.ko 'No configured commands found' if list.keys.empty?
      list.keys.each do |command|
        log.item "#{command.to_s}"
        if options[:detail] then
          log.arrow "command line : '#{list[command][:command]}'"
          log.arrow "command description : '#{list[command][:desc]}'"
          log.arrow "command failure callback : '#{list[command.to_sym][:on_failure]}'" if list[command.to_sym][:on_failure]
          log.arrow "command success callback : '#{list[command.to_sym][:on_success]}'" if list[command.to_sym][:on_success]
          if list[command.to_sym][:schedule]
            sched,val = list[command.to_sym][:schedule].flatten
            log.arrow "command scheduled : #{sched} #{val}."
          end
        end
      end
      splash_exit case: :quiet_exit
    end

    # Thor method: getting informations about a specific splash configuration defined command
    desc "show COMMAND", "Show specific configured command COMMAND"
    long_desc <<-LONGDESC
    Show specific configured command COMMAND\n
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)
    LONGDESC
    option :hostname, :type => :string,  :aliases => "-H"
    def show(command)
      unless is_root? then
        splash_exit case: :not_root, :more => "Command show specifications"
      end
      log = get_logger
      list = {}
      if options[:hostname] then
        options[:hostname] = Socket.gethostname if options[:hostname] == 'hostname'
        log.info "Remote Splash configured commands on #{options[:hostname]}:"
        log.info "ctrl+c for interrupt"
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
        log.receive "Receving list of commands from #{options[:hostname]}"
      else
        list = get_config.commands
      end
      if list.keys.include? command.to_sym then
        log.info "Splash command : #{command}"
        log.item "command line : '#{list[command.to_sym][:command]}'"
        log.item "command description : '#{list[command.to_sym][:desc]}'"
        log.item "command failure callback : '#{list[command.to_sym][:on_failure]}'" if list[command.to_sym][:on_failure]
        log.item "command success callback : '#{list[command.to_sym][:on_success]}'" if list[command.to_sym][:on_success]
        if list[command.to_sym][:schedule]
          sched,val = list[command.to_sym][:schedule].flatten
          log.item "command scheduled : #{sched} #{val}."
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => 'Command not configured'
      end
    end



    # Thor method : show commands executions  history
    long_desc <<-LONGDESC
    show commands executions history for LABEL\n
    LONGDESC
    option :table, :type => :boolean,  :aliases => "-t"
    desc "history LABEL", "show commands executions history"
    def history(command)
      if is_root? then
        log = get_logger
        log.info "Command : #{command}"
        config = get_config
        if options[:table] then
          table = TTY::Table.new do |t|
            t << ["Start Date","Status", "end_date", "Execution time","STDOUT empty ? ", "STDERR empty ? "]
            t << ['','','','','','']
            CmdRecords::new(command).get_all_records.each do |item|
              record =item.keys.first
              value=item[record]
              t << [record, value[:status].to_s,
                            value[:end_date],
                            value[:exec_time],
                            value[:stdout].empty?,
                            value[:stdout].empty?]
            end
          end
          if check_unicode_term  then
            puts table.render(:unicode)
          else
            puts table.render(:ascii)
          end

        else
          CmdRecords::new(command).get_all_records.each do |item|
            record =item.keys.first
            value=item[record]
            log.item record
            log.arrow "Status : #{value[:status].to_s}"
            log.arrow "End date : #{value[:end_date]}"
            log.arrow "Execution time : #{value[:exec_time]}"
            log.arrow "STDOUT empty ?  : #{value[:stdout].empty?}"
            log.arrow "STDERR empty ?  : #{value[:stderr].empty?}"
          end
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_root, :more => "Command execution history"
      end
    end

    # Thor method : getting information on the last execution of a command
    desc "lastrun COMMAND", "Show last running result for specific configured command COMMAND"
    long_desc <<-LONGDESC
    Show last running result for specific configured command COMMAND\n
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)
    LONGDESC
    option :hostname, :type => :string,  :aliases => "-H"
    def lastrun(command)
      unless is_root? then
        splash_exit case: :not_root, :more => "Command last execution report"
      end
      log = get_logger
      backend = get_backend :execution_trace
      redis = (backend.class == Splash::Backends::Redis)? true : false
      if not redis and options[:hostname] then
        splash_exit case: :specific_config_required, :more => "Redis backend is requiered for Remote execution report request"
      end
      splash_exit case: :not_root if not is_root? and not redis
      list = get_config.commands.keys
      if options[:hostname] then
        options[:hostname] = Socket.gethostname if options[:hostname] == 'hostname'
        list = backend.list("*", options[:hostname]).map(&:to_sym)
      end
      if list.include? command.to_sym then
        log.info "Splash command #{command} previous execution report:\n"
        req  = { :key => command}
        req[:hostname] = options[:hostname] if options[:hostname]
        if backend.exist? req then
          res = backend.get req
          tp = Template::new(
              list_token: get_config.execution_template_tokens,
              template_file: get_config.execution_template_path)
          tp.map YAML::load(res).last.values.first
          log.flat tp.output
        else
          log.ko "Command not already runned."
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => "Command report never runned remotly" if options[:hostname]
      end
    end


    # Thor method : getting information on one specific execution of a command
    desc "onerun COMMAND", "Show running result for specific configured command COMMAND"
    long_desc <<-LONGDESC
    Show specific running result for specific configured command COMMAND\n
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)
    with --date <DATE>, a date format string (same as in history ouput)

    LONGDESC
    option :hostname, :type => :string,  :aliases => "-H"
    option :date, :type => :string,  :aliases => "-D", :required => true
    def onerun(command)
      unless is_root? then
        splash_exit case: :not_root, :more => "Command specific execution report"
      end
      log = get_logger
      backend = get_backend :execution_trace
      redis = (backend.class == Splash::Backends::Redis)? true : false
      if not redis and options[:hostname] then
        splash_exit case: :specific_config_required, :more => "Redis backend is requiered for Remote execution report request"
      end
      splash_exit case: :not_root if not is_root? and not redis
      list = get_config.commands.keys
      if options[:hostname] then
        options[:hostname] = Socket.gethostname if options[:hostname] == 'hostname'
        list = backend.list("*", options[:hostname]).map(&:to_sym)
      end
      if list.include? command.to_sym then
        log.info "Splash command #{command} previous execution report:\n"
        req  = { :key => command}
        req[:hostname] = options[:hostname] if options[:hostname]
        if backend.exist? req then
          res = backend.get req
          tp = Template::new(
              list_token: get_config.execution_template_tokens,
              template_file: get_config.execution_template_path)
          prov =  YAML::load(res).select{|key,value| key.keys.first == options[:date]}
          if prov.empty? then
            log.ko "Command not runned one this date or date misformatted."
          else
            tp.map prov.first.values.first
            log.flat tp.output
          end
        else
          log.ko "Command not already runned."
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => "Command report never runned remotly" if options[:hostname]
      end
    end

    # Thor method : getting the list of avaibles executions reports
    desc "getreportlist", "list all executions report results "
    long_desc <<-LONGDESC
    list all executions report results\n
    with --pattern <SEARCH>, search type string, wilcard * (group) ? (char)\n
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)\n
    with --all, get all execution report for all servers (only with Redis backend configured)\n
    with --detail, get major informations of each reports\n
    --all and --hostname are exclusives
    LONGDESC
    option :pattern, :type => :string, :aliases => "-p"
    option :hostname, :type => :string,  :aliases => "-H"
    option :all, :type => :boolean, :negate => false,  :aliases => "-A"
    option :detail, :type => :boolean,  :aliases => "-D"
    def getreportlist
      unless is_root? then
        splash_exit case: :not_root, :more => "Command execution report list"
      end
      log = get_logger
      options[:hostname] = Socket.gethostname if options[:hostname] == 'hostname'
      if options[:hostname] and options[:all] then
        splash_exit case: :options_incompatibility, more: "--all, --hostname"
      end
      backend = get_backend :execution_trace
      redis = (backend.class == Splash::Backends::Redis)? true : false
      if not redis and (options[:hostname] or options[:all]) then
        splash_exit case: :specific_config_required, more: "Redis Backend requiered for Remote execution report Request"
      end
      splash_exit case: :not_root if not is_root? and not redis
      pattern = (options[:pattern])? options[:pattern] : '*'
      if options[:all] then
        res = backend.listall pattern
      elsif options[:hostname]
        res = backend.list pattern, options[:hostname]
      else
        res = backend.list pattern
      end
      log.info "List of Executions reports :\n"
      log.ko "Not reports found" if res.empty?
      res.each do |item|
        host = ""
        command = ""
        if options[:all]
          host,command = item.split('#')
          log.item "Command : #{command} @ host : #{host}"
        else
          command = item
          log.item "Command : #{command}"
        end
        if options[:detail] then
          req = { :key => command }
          req[:hostname] = host if options[:all]
          res = YAML::load(backend.get(req))
          res.each do |record|
            log.arrow "#{record.keys.first} : #{record[record.keys.first][:status]}"
          end
        end
      end
      splash_exit case: :quiet_exit
    end

  end
end
