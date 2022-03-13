# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for Processes management
  class WebAdmin < Thor
    include Splash::WebAdmin::Controller
    include Splash::Config
    include Splash::Exiter
    include Splash::Helpers


    # Thor method : stopping Splash Webadmin
    desc "stop", "Stopping Splash Webadmin Daemon"
    def stop
      acase = run_as_root :stopweb, options
      splash_exit acase
    end

    # Thor method : getting execution status of Splashd
    desc "status", "Splash WebAdmin Daemon status"
    def status
      acase = run_as_root :statusweb, options
      splash_exit acase
    end







    # Thor method : getting execution status of Splash WebAdmin
    long_desc <<-LONGDESC
    Starting Splash Daemon\n
    LONGDESC
    option :foreground, :type => :boolean,  :aliases => "-F"
    desc "start", "Splash WebAdmin Daemon status"
    def start
      acase = run_as_root :startweb, options
      splash_exit acase
    end

  end

end
