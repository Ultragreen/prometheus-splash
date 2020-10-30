# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for configuration management
  class Config < Thor
    include Splash::ConfigUtilities
    include Splash::Helpers
    include Splash::Exiter
    include Splash::Loggers
    include Splash::Backends

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
    option :name, :type => :string,  :aliases => "-N"
    def flushbackend
      if options[:name] then
        acase = run_as_root :flush_backend, options
      else
        return_cases = {}
        list_backends.each do |key,value|
          return_cases[key] = run_as_root :flush_backend, { :name => key }
        end
        errors = return_cases.select {|key,value| value[:case] != :quiet_exit}.keys
        acase = (errors.empty?)? {:case => :quiet_exit, :more => "All backends flushed successfully"}: {:case => :configuration_error, :more => "Backends #{errors.join(',')} flushing failed"}
      end
      splash_exit acase
    end


  end

end
