module Splash
  module Config
    CONFIG_FILE = "/etc/splash.yml"
    def setupsplash
      conf_in_path = search_file_in_gem "splash", "config/splash.yml"
      install_file source: conf_in_path, target: CONFIG_FILE, mode: "644", owner: "root", group: "wheel"
    end

    def checkconfig
      print "Config file : #{CONFIG_FILE}"
      res = verify_file(name: CONFIG_FILE, mode: "644", owner: "root", group: "wheel")
      if res.empty? then
        print "[OK]\n"
      else
        print "[KO]\n"
        print res
      end
    end

    private
    def search_file_in_gem(_gem,_file)
      if Gem::Specification.respond_to?(:find_by_name)
        begin
          spec = Gem::Specification.find_by_name(_gem)
        rescue LoadError
          spec = nil
        end
      else
        spec = Gem.searcher.find(_gem)
      end
      if spec then
        if Gem::Specification.respond_to?(:find_by_name)
          res = spec.lib_dirs_glob.split('/')
        else
          res = Gem.searcher.lib_dirs_for(spec).split('/')
        end
        res.pop
        services_path = res.join('/').concat("/#{_file}")
        return services_path if File::exist?(services_path)
        return false
      else
        return false
      end
    end

  end
end
