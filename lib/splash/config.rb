module Splash
  module Config
    include Splash::Helpers
    include Splash::Constants



    class Configuration < Hash
      include Splash::Constants
      def initialize(config_file=CONFIG_FILE)
        config_from_file = readconf config_file
        self[:version] = VERSION
        self[:author] = "#{AUTHOR} <#{EMAIL}>"
        self[:copyright] = "#{COPYRIGHT} #{LICENSE}"
        self[:prometheus_pushgateway_host] = (config_from_file[:prometheus][:pushgateway][:host])? config_from_file[:prometheus][:pushgateway][:host] : PROMETHEUS_PUSHGATEWAY_HOST
        self[:prometheus_pushgateway_port] = (config_from_file[:prometheus][:pushgateway][:port])? config_from_file[:prometheus][:pushgateway][:port] : PROMETHEUS_PUSHGATEWAY_PORT
        self[:daemon_process_name] = (config_from_file[:daemon][:process_name])? config_from_file[:daemon][:process_name] : DAEMON_PROCESS_NAME
        self[:daemon_user] = (config_from_file[:daemon][:user])? config_from_file[:daemon][:user] : DAEMON_USER
        self[:execution_template] = (config_from_file[:templates][:execution])? config_from_file[:template][:execution] : EXECUTION_TEMPLATE
        self[:daemon_group] = (config_from_file[:daemon][:group])? config_from_file[:daemon][:group] : DAEMON_GROUP
        self[:pid_path] = (config_from_file[:daemon][:paths][:pid_path])? config_from_file[:daemon][:paths][:pid_path] : PID_PATH
        self[:trace_path] = (config_from_file[:daemon][:paths][:trace_path])? config_from_file[:daemon][:paths][:trace_path] : TRACE_PATH
        self[:pid_file] = (config_from_file[:daemon][:files][:pid_file])? config_from_file[:daemon][:files][:pid_file] : PID_FILE
        self[:stdout_trace] = (config_from_file[:daemon][:files][:stdout_trace])? config_from_file[:daemon][:files][:stdout_trace] : STDOUT_TRACE
        self[:stderr_trace] = (config_from_file[:daemon][:files][:stderr_trace])? config_from_file[:daemon][:files][:stderr_trace] : STDERR_TRACE
        self[:logs] = (config_from_file[:logs])? config_from_file[:logs] : {}
        self[:commands] = (config_from_file[:commands])? config_from_file[:commands] : {}

      end

      def execution_template
        return self[:execution_template]
      end

      def logs
        return self[:logs]
      end

      def commands
        return self[:commands]
      end

      def author
        return self[:author]
      end

      def copyright
        return self[:copyright]
      end

      def version
        return self[:version]
      end

      def daemon_process_name
        return self[:daemon_process_name]
      end

      def prometheus_pushgateway_host
        return self[:prometheus_pushgateway_host]
      end
      def prometheus_pushgateway_port
        return self[:prometheus_pushgateway_port]
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

      private
      def readconf(file = CONFIG_FILE)
        return YAML.load_file(file)[:splash]
      end


    end


    def get_config(config_file=CONFIG_FILE)
      return Configuration::new config_file
    end


    def setupsplash
      conf_in_path = search_file_in_gem "prometheus-splash", "config/splash.yml"
      full_res = 0
      puts "Splash -> setup : "
      print "* Installing Configuration file : #{CONFIG_FILE} : "
      if install_file source: conf_in_path, target: CONFIG_FILE, mode: "644", owner: "root", group: "wheel" then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end
      config = get_config
      report_in_path = search_file_in_gem "prometheus-splash", "templates/report.txt"
      print "* Installing template file : #{config.execution_template} : "
      if install_file source: report_in_path, target: config.execution_template, mode: "644", owner: "root", group: "wheel" then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      print "* Creating/Checking pid file path : #{config[:pid_path]} : "
      if make_folder path: config[:pid_path], mode: "644", owner: "root", group: "wheel" then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      print "* Creating/Checking trace file path : #{config[:trace_path]} : "
      if make_folder path: config[:trace_path], mode: "777", owner: config.daemon_user, group: config.daemon_group then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      if full_res > 0 then
        $stderr.puts "Splash config done with #{full_res} errors"
        return 25
      else
        puts "Splash config successfully done."
        return 0
      end

    end

    def checkconfig
      puts "Splash -> sanitycheck : "
      config = get_config
      full_res = 0
      print "* Config file : #{CONFIG_FILE} : "
      res = verify_file(name: CONFIG_FILE, mode: "644", owner: "root", group: "wheel")
      if res.empty? then
        print "[OK]\n"
      else
        print "[KO]\n"
        full_res =+ 1
        puts "    pbm => #{res.map {|p| p.to_s}.join(',')}"
      end

      print "* PID Path : #{config[:pid_path]} : "
      res = verify_folder(name: config[:pid_path], mode: "644", owner: "root", group: "wheel")
      if res.empty? then
        print "[OK]\n"
      else
        print "[KO]\n"
        full_res =+ 1
        puts "    pbm => #{res.map {|p| p.to_s}.join(',')}"

      end

      print "* trace Path : #{config[:trace_path]} : "
      res = verify_folder(name: config[:trace_path], mode: "777", owner: config.daemon_user, group: config.daemon_group)
      if res.empty? then
        print "[OK]\n"
      else
        print "[KO]\n"
        full_res =+ 1
        puts "    pbm => #{res.map {|p| p.to_s}.join(',')}"
      end

      print "* Prometheus PushGateway Service running : "
      if verify_service host: config.prometheus_pushgateway_host ,port: config.prometheus_pushgateway_port then
        print "[OK]\n"
      else
        print "[KO]\n"
        full_res =+ 1
      end

      if full_res > 0 then
        $stderr.puts "Sanitycheck finished with #{full_res} errors"
        return 20
      else
        puts "Sanitycheck finished with no errors"
        return 0
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
