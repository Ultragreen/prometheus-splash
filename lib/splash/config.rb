module Splash
  module Config

    def setup
    end

    def checkconfig
      print "Config file : /etc/splash.yml"
      if verify_file("/etc/splash.yml") then
        print "[OK]\n"
      else
        print "[KO]\n"
      end
    end
  end
end
