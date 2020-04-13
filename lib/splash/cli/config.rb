# coding: utf-8
module CLISplash

  class Config < Thor
    include Splash::ConfigUtilities
    include Splash::Helpers
    include Splash::Exiter
    include Splash::Loggers


    desc "setup", "Setup installation fo Splash"
    long_desc <<-LONGDESC
    Setup installation fo Splash\n
    with --preserve, preserve from reinstallation of the config
    LONGDESC
    option :preserve, :type => :boolean
    def setup
      acase = run_as_root :setupsplash, options
      splash_exit acase
    end

    desc "sanitycheck", "Verify installation fo Splash"
    def sanitycheck
      acase = run_as_root :checkconfig
      splash_exit acase
    end

    desc "version", "display current Splash version"
    def version
      log = get_logger
      config = get_config
      log.info "Splash version : #{config.version}, Author : #{config.author}"
      log_info config.copyright
      splash_exit case: :quiet_exit
    end

  end

end
