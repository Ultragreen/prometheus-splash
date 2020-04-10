# coding: utf-8
module CLISplash


  class Commands < Thor
    include Splash::Config
    include Splash::Backends
    include Splash::Exiter

    desc "execute NAME", "run for command/sequence or ack result"
    long_desc <<-LONGDESC
    execute command or sequence or ack result
    with --no-trace prevent storing execution trace in configured backend (see config file)
    with --ack, notify errorcode=0 to Prometheus PushGateway
    with --no-notify, bypass Prometheus notification
    with --no-callback, never execute callback (:on_failure, :on_success)
                        never follow sequences
    LONGDESC
    option :trace, :type => :boolean, :default => true
    option :ack, :type => :boolean, negate: false
    option :notify, :type => :boolean, :default => true
    option :callback, :type => :boolean, :default => true
    def execute(name)
      if is_root? then
        command =  Splash::CommandWrapper::new(name)
        command.ack if options[:ack]
        command.call_and_notify trace: options[:trace], notify: options[:notify], callback: options[:callback]
      else
        splash_exit status: :error, case: :not_root
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
    end


    desc "list", "Show configured commands"
    long_desc <<-LONGDESC
    Show configured commands
    with --detail, show command details
    LONGDESC
    option :detail, :type => :boolean
    def list
      puts "Splash configured commands :"
      list = get_config.commands
      puts 'No configured commands found' if list.keys.empty?
      list.keys.each do |command|
        puts " * #{command.to_s}"
        if options[:detail] then
          puts "   - command line : '#{list[command][:command]}'"
          puts "   - command description : '#{list[command][:desc]}'"
          puts "   - command failure callback : '#{list[command.to_sym][:on_failure]}'" if list[command.to_sym][:on_failure]
          puts "   - command success callback : '#{list[command.to_sym][:on_success]}'" if list[command.to_sym][:on_success]
        end
      end
    end


    desc "show COMMAND", "Show specific configured command COMMAND"
    def show(command)
      list = get_config.commands
      if list.keys.include? command.to_sym then
        puts "Splash command : #{command}"
        puts "   - command line : '#{list[command.to_sym][:command]}'"
        puts "   - command description : '#{list[command.to_sym][:desc]}'"
        puts "   - command failure callback : '#{list[command.to_sym][:on_failure]}'" if list[command.to_sym][:on_failure]
        puts "   - command success callback : '#{list[command.to_sym][:on_success]}'" if list[command.to_sym][:on_success]
      else
        $stderr.puts "Command not configured"
        exit 50
      end
    end


    desc "lastrun COMMAND", "Show last running result for specific configured command COMMAND"
    long_desc <<-LONGDESC
    Show last running result for specific configured command COMMAND
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)
    LONGDESC
    option :hostname, :type => :string
    def lastrun(command)
      backend = get_backend :execution_trace
      redis = (backend.class == Splash::Backends::Redis)? true : false
      if not redis and options[:hostname] then
        $stderr.puts "Remote execution report request only possible with Redis backend"
      end
      list = get_config.commands
      if list.keys.include? command.to_sym then
        print "Splash command #{command} previous execution report:\n\n"
        req  = { :key => command}
        req[:hostname] = options[:hostname] if options[:hostname]
        if backend.exist? req then
          print backend.get req
        else
          puts "Command not already runned."
        end
      else
        $stderr.puts "Command not configured"
        exit 50
      end
    end

    desc "getreportlist COMMAND", "list all executions report results "
    long_desc <<-LONGDESC
    Show configured commands
    with --pattern <SEARCH>, search type string, wilcard * (group) ? (char)
    with --hostname <HOSTNAME>, an other Splash monitored server (only with Redis backend configured)
    with --all, get all execution report for all servers (only with Redis backend configured)
    --all and --hostname are exclusives
    LONGDESC
    option :pattern, :type => :string
    option :hostname, :type => :string
    option :all, :type => :boolean, :negate => false
    def getreportlist
      if options[:hostname] and options[:all] then
        $stderr.puts "--all option imcompatible with --hostname"
        exit 40
      end
      backend = get_backend :execution_trace
      redis = (backend.class == Splash::Backends::Redis)? true : false
      if not redis and (options[:hostname] or options[:all]) then
        $stderr.puts "Remote execution report request only possible with Redis backend"
        exit 40
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
        if options[:all]
          host,command = item.split('#')
          puts " * Command : #{command} @ host : #{host}"
        else
          puts " * Command : #{item}"
        end
      end
    end

  end
end
