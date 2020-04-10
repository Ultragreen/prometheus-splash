module CLISplash

  class Config < Thor
    include Splash::Config
    include Splash::Helpers

    desc "setup", "Setup installation fo Splash"
    long_desc <<-LONGDESC
    Setup installation fo Splash
    with --preserve, preserve from reinstallation of the config
    LONGDESC
    option :preserve, :type => :boolean
    def setup
      errorcode = run_as_root :setupsplash
      exit errorcode
    end

    desc "sanitycheck", "Verify installation fo Splash"
    def sanitycheck
      errorcode = run_as_root :checkconfig
      exit errorcode
    end

    desc "version", "display current Splash version"
    def version
      config = get_config
      puts "Splash version : #{config.version}, Author : #{config.author}"
      puts config.copyright
    end

  end

end
