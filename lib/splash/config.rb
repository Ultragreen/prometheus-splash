module Splash
  module Config
    include Splash::Helpers
    include Splash::Constants



    class Configuration < Hash
      def initilize(config_file=CONFIG_FILE)
        config_from_file = readconf config_file
        self[:version] = VERSION
        self[:daemon_process_name] = (config_from_file[:daemon][:process_name])? config_from_file[:daemon][:process_name] : DAEMON_PROCESS_NAME
        self[:daemon_user] = (config_from_file[:daemon][:user])? config_from_file[:daemon][:user] : DAEMON_USER
        self[:daemon_group] = (config_from_file[:daemon][:group])? config_from_file[:daemon][:group] : DAEMON_GROUP
        self[:pid_path] = (config_from_file[:daemon][:path][:pid_path])? config_from_file[:daemon][:paths][:pid_path] : PID_PATH
        self[:trace_path] = (config_from_file[:daemon][:path][:trace_path])? config_from_file[:daemon][:paths][:trace_path] : TRACE_PATH
        self[:pid_file] = (config_from_file[:daemon][:files][:pid_file])? config_from_file[:daemon][:files][:pid_file] : PID_FILE
        self[:stdout_trace] = (config_from_file[:daemon][:files][:stdout_trace])? config_from_file[:daemon][:files][:stdout_trace] : STDOUT_TRACE
        self[:stderr_trace] = (config_from_file[:daemon][:files][:stderr_trace])? config_from_file[:daemon][:files][:stderr_trace] :  : STDERR_TRACE
      end

      def version
        return self[:version]
      end

      def daemon_process_name
        return self[:daemon_process_name]
      end

      def daemon_user
        return self[:daemon_user]
      end

      def daemon_group
        return self[:daemon_group]
      end

      def full_pid_path
        return "#{self[:pid_path]}/#{self[:pid_file]}"
      end

      def full_stdout_trace_path
        return "#{self[:trace_path]}/#{self[:stdout_trace]}"
      end

      def full_stderr_trace_path
        return "#{self[:trace_path]}/#{self[:stderr_trace]}"
      end


    end


    def get_config(config_file)
      return Configuration::new config_file
    end


    def setupsplash
      conf_in_path = search_file_in_gem "splash", "config/splash.yml"

      print "* Configuration file : #{CONFIG_FILE} : "
      if install_file source: conf_in_path, target: CONFIG_FILE, mode: "644", owner: "root", group: "wheel" then
        puts "[OK]"
      else
        puts "[KO]"
      end
      config = get_config

      print "* Checking pid file path : #{config.full_pid_path}"
      if make_folder path: config.full_pid_path, mode: "644", owner: "root", group: "wheel" then
        puts "[OK]"
      else
        puts "[KO]"
      end

      print "* Checking trace file path : #{config[:trace_path]}"
      if make_folder path: config[:trace_path], mode: "644", owner: config.daemon_user, group: config.daemon_group then
        puts "[OK]"
      else
        puts "[KO]"
      end

      puts "Splash config done. "

    end

    def checkconfig
      config = get_config
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
    def readconf(file = CONFIG_FILE)
      return YAML.load_file(file)[:logs]
    end

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
