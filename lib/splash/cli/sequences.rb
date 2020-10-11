# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for sequences management
  class Sequences < Thor
    include Splash::Sequences
    include Splash::Transports
    include Splash::Exiter
    include Splash::Loggers


    # Thor method : execute sequence
    option :continue, :type => :boolean, default: true
    long_desc <<-LONGDESC
    Execute a commands Sequence\n
    With --no-continue, stop execution on failure
    LONGDESC
    desc "execute", "Execute a sequence"
    def execute(sequence)
      options[:name] = sequence
      acase = run_as_root :run_seq, options
      splash_exit acase
    end


    # Thor method : show sequence
    long_desc <<-LONGDESC
    Show a commands Sequence\n
    LONGDESC
    desc "show", "Show a sequence"
    def show(sequence)
      options = {}
      log = get_logger
      options[:name] = sequence
      acase = run_as_root :show_seq, options
      unless acase[:data].nil? then
        dseq = acase[:data]
        log.item sequence
        unless dseq[:options].nil? then
          log.arrow "Options : "
          log.flat  "    * continue on failure : #{dseq[:options][:continue]}" unless dseq[:options][:continue].nil?
        end
        log.arrow "Definition :"
        dseq[:definition].each do |step|
          log.flat "    * Step name : #{step[:step]}"
          log.flat "      => Splash Command to execute : #{step[:command]}"
          log.flat "      => Execute remote on host : #{step[:on_host]}" unless step[:on_host].nil?
          log.flat "      => Follow Callback : #{step[:callback]}" unless step[:callback].nil?
          log.flat "      => Prometheus notification : #{step[:notification]}" unless step[:notification].nil?
        end
      end
      splash_exit acase
    end


    # Thor method : getting the list of available sequences in splash config
    desc "list", "Show configured sequences"
    long_desc <<-LONGDESC
    Show configured sequences\n
    with --detail, show command details\n
    LONGDESC
    option :detail, :type => :boolean,  :aliases => "-D"
    def list
      acase = run_as_root :list_seq, options
      log = get_logger
      unless acase[:data].nil?
        log.info "Splash configured sequences"
        acase[:data].keys.each do |seq|
          log.item seq
          if options[:detail] then
            dseq = acase[:data][seq]
            unless dseq[:options].nil? then
              log.arrow "Options : "
              log.flat  "    * continue on failure : #{dseq[:options][:continue]}" unless dseq[:options][:continue].nil?
            end
            log.arrow "Definition :"
            dseq[:definition].each do |step|
              log.flat "    * Step name : #{step[:step]}"
              log.flat "      => Splash Command to execute : #{step[:command]}"
              log.flat "      => Execute remote on host : #{step[:on_host]}" unless step[:on_host].nil?
              log.flat "      => Follow Callback : #{step[:callback]}" unless step[:callback].nil?
              log.flat "      => Prometheus notification : #{step[:notification]}" unless step[:notification].nil?
            end
          end
        end
      end
      splash_exit acase
    end


    # Thor method : scheduling execution of a commands sequences in splash daemon
    desc "schedule", "Schedule a configured sequences execution"
    long_desc <<-LONGDESC
    Schedule excution of command sequence on Splash daemon\n
    with --at TIME/DATE, Schedule at specified date/time, like 2030/12/12 23:30:00 or 12:00 \n
    with --in TIMING, Schedule in specified timing, like 12s, 1m, 2h, 3m10s, 10d\n
    --in and --at are imcompatibles.\n
    WARNING : scheduling by CLI are not percisted, so use it only for specifics cases.\n
    LONGDESC
    option :at, :type => :string
    option :in, :type => :string
    def schedule(sequence)
      options[:sequence] = sequence
      acase = run_as_root :schedule_seq, options
      splash_exit acase
    end

  end

end
