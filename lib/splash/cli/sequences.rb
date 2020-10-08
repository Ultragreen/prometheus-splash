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
      options[:sequence] = sequence
      acase = run_as_root :run_seq, options
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
