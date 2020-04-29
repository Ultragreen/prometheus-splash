# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for configuration management
  class Config < Thor
    include Splash::ConfigUtilities
    include Splash::Helpers
    include Splash::Exiter
    include Splash::Loggers

    # Thor method : running of Splash setup
    desc "setup", "Setup installation fo Splash"
    long_desc <<-LONGDESC
    Setup installation fo Splash\n
    with --preserve, preserve from reinstallation of the config
    LONGDESC
    option :preserve, :type => :boolean,  :aliases => "-P"
    def setup
      acase = run_as_root :setupsplash, options
      splash_exit acase
    end

    # Thor method : running of Splash sanitycheck
    desc "sanitycheck", "Verify installation fo Splash"
    def sanitycheck
      acase = run_as_root :checkconfig
      splash_exit acase
    end

    # Thor method : Getting the current Splash version
    desc "version", "Display current Splash version"
    def version
      log = get_logger
      config = get_config
      log.info "Splash version : #{config.version}, Author : #{config.author}"
      log.info config.copyright
      splash_exit case: :quiet_exit
    end

    # Thor method : Installing Splashd Systemd service file
    desc "service", "Install Splashd Systemd service"
    def service
      acase = run_as_root :addservice
      splash_exit acase
    end


    # Thor method : flushing configured backend
    desc "flushbackend", "Flush configured backend"
    def flushbackend
      acase = run_as_root :flush_backend
      splash_exit acase
    end


  end

end
