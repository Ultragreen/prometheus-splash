# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for Processes management
  class WebAdmin < Thor
    include Splash::Config
    include Splash::Exiter
    include Splash::Helpers


    # Thor method : stopping Splash Webadmin
    desc "stop", "Stopping Splash Webadmin Daemon"
    def stop
    end

    # Thor method : getting execution status of Splashd
    desc "status", "Splash WebAdmin Daemon status"
    def status
    end



  



    # Thor method : getting execution status of Splash WebAdmin
    option :foreground, :type => :boolean,  :aliases => "-F"
    long_desc <<-LONGDESC
    Starting Splash Daemon\n
    With --foreground, run Splash WebAdmin in foreground\n
    LONGDESC
    desc "start", "Splash WebAdmin Daemon status"
    def start
      unless is_root?
        splash_exit :case => :not_root, :more => "WebAdmin need to be run as root"
      else
        require 'splash/webadmin/main'
      end
    end

  end

end
