# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for Processes management
  class WebAdmin < Thor
    include Splash::Config
    include Splash::Exiter


    # Thor method : stopping Splash Webadmin
    desc "stop", "Stopping Splash Webadmin Daemon"
    def stop
    end

    # Thor method : getting execution status of Splashd
    desc "status", "Splash Daemon status"
    def status
    end

    # Thor method : getting execution status of Splashd
    desc "start", "Splash Daemon status"
    def status
      require 'api/main'
    end

  end

end
