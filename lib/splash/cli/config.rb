# coding: utf-8
module CLISplash

  class Config < Thor
    include Splash::Config
    include Splash::Helpers
    include Splash::Exiter


    desc "setup", "Setup installation fo Splash"
    long_desc <<-LONGDESC
    Setup installation fo Splash\n
    with --preserve, preserve from reinstallation of the config
    LONGDESC
    option :preserve, :type => :boolean
    def setup
      acase = run_as_root :setupsplash
      splash_exit acase
    end

    desc "sanitycheck", "Verify installation fo Splash"
    def sanitycheck
      acase = run_as_root :checkconfig
      splash_exit acase
    end

    desc "version", "display current Splash version"
    def version
      config = get_config
      puts "Splash version : #{config.version}, Author : #{config.author}"
      puts config.copyright
      splash_exit case: :quiet_exit
    end

  end

end
