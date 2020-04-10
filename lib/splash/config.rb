# coding: utf-8
module Splash
  module Config
    include Splash::Helpers
    include Splash::Constants


    # Class to manage configuration in Splash from Splash::Constants override by Yaml CONFIG
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
        self[:daemon_logmon_scheduling] = (config_from_file[:daemon][:logmon_scheduling])? config_from_file[:daemon][:logmon_scheduling] : DAEMON_LOGMON_SCHEDULING
        self[:execution_template_tokens] = EXECUTION_TEMPLATE_TOKENS_LIST
        self[:execution_template_path] = (config_from_file[:templates][:execution][:path])? config_from_file[:templates][:execution][:path] : EXECUTION_TEMPLATE
        self[:pid_path] = (config_from_file[:daemon][:paths][:pid_path])? config_from_file[:daemon][:paths][:pid_path] : DAEMON_PID_PATH
        self[:trace_path] = (config_from_file[:daemon][:paths][:trace_path])? config_from_file[:daemon][:paths][:trace_path] : TRACE_PATH
        self[:pid_file] = (config_from_file[:daemon][:files][:pid_file])? config_from_file[:daemon][:files][:pid_file] : DAEMON_PID_FILE
        self[:stdout_trace] = (config_from_file[:daemon][:files][:stdout_trace])? config_from_file[:daemon][:files][:stdout_trace] : DAEMON_STDOUT_TRACE
        self[:stderr_trace] = (config_from_file[:daemon][:files][:stderr_trace])? config_from_file[:daemon][:files][:stderr_trace] : DAEMON_STDERR_TRACE

        self[:transports] = {} ; self[:transports].merge! TRANSPORTS_STRUCT ; self[:transports].merge! config_from_file[:transports] if config_from_file[:transports]
        self[:backends] = {} ; self[:backends].merge! BACKENDS_STRUCT ; self[:backends].merge! config_from_file[:backends] if config_from_file[:backends]

        self[:logs] = (config_from_file[:logs])? config_from_file[:logs] : {}
        self[:commands] = (config_from_file[:commands])? config_from_file[:commands] : {}

      end

      # @!group accessors on configurations Items

      def Configuration.user_root
        return Etc.getpwuid(0).name
      end

      def Configuration.group_root
        return Etc.getgrgid(0).name
      end

      def user_root
        return Configuration.user_root
      end

      def group_root
        return Configuration.group_root
      end


      def backends
        return self[:backends]
      end

      def transports
        return self[:transports]
      end

      def daemon_logmon_scheduling
        return self[:daemon_logmon_scheduling]
      end

      def execution_template_path
        return self[:execution_template_path]
      end
      def execution_template_tokens
        return self[:execution_template_tokens]
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

      def full_pid_path
        return "#{self[:pid_path]}/#{self[:pid_file]}"
      end

      def full_stdout_trace_path
        return "#{self[:trace_path]}/#{self[:stdout_trace]}"
      end

      def full_stderr_trace_path
        return "#{self[:trace_path]}/#{self[:stderr_trace]}"
      end

      # @!endgroup

      private
      def readconf(file = CONFIG_FILE)
        return YAML.load_file(file)[:splash]
      end


    end

    # factory of Configuration Class instance
    # @param [String] config_file the path of the YAML Config file
    # @return [SPlash::Config::Configuration]
    def get_config(config_file=CONFIG_FILE)
      return Configuration::new config_file
    end

    # Setup action method for installing Splash
    # @return [Integer] an errorcode value
    def setupsplash
      conf_in_path = search_file_in_gem "prometheus-splash", "config/splash.yml"
      full_res = 0
      puts "Splash -> setup : "
      unless options[:preserve] then
        print "* Installing Configuration file : #{CONFIG_FILE} : "
        if install_file source: conf_in_path, target: CONFIG_FILE, mode: "644", owner: Configuration.user_root, group: Configuration.group_root then
          puts "[OK]"
        else
          full_res =+ 1
          puts "[KO]"
        end
      else
        puts "Config file preservation."
      end
      config = get_config
      report_in_path = search_file_in_gem "prometheus-splash", "templates/report.txt"
      print "* Installing template file : #{config.execution_template_path} : "
      if install_file source: report_in_path, target: config.execution_template_path, mode: "644", owner: config.user_root, group: config.group_root then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      print "* Creating/Checking pid file path : #{config[:pid_path]} : "
      if make_folder path: config[:pid_path], mode: "644", owner: config.user_root, group: config.group_root then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      print "* Creating/Checking trace file path : #{config[:trace_path]} : "
      if make_folder path: config[:trace_path], mode: "644", owner: config.user_root, group: config.group_root then
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

    # Sanitycheck action method for testing installation of Splash
   # @return [Integer] an errorcode value
    def checkconfig
      puts "Splash -> sanitycheck : "
      config = get_config
      full_res = 0
      print "* Config file : #{CONFIG_FILE} : "
      res = verify_file(name: CONFIG_FILE, mode: "644", owner: config.user_root, group: config.group_root)
      if res.empty? then
        print "[OK]\n"
      else
        print "[KO]\n"
        full_res =+ 1
        puts "    pbm => #{res.map {|p| p.to_s}.join(',')}"
      end

      print "* PID Path : #{config[:pid_path]} : "
      res = verify_folder(name: config[:pid_path], mode: "644", owner: config.user_root, group: config.group_root)
      if res.empty? then
        print "[OK]\n"
      else
        print "[KO]\n"
        full_res =+ 1
        puts "    pbm => #{res.map {|p| p.to_s}.join(',')}"

      end

      print "* trace Path : #{config[:trace_path]} : "
      res = verify_folder(name: config[:trace_path], mode: "777", owner: config.user_root, group: config.group_root)
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

    # facilities to find a file in gem path
    # @param [String] _gem a Gem name
    # @param [String] _file a file relative path in the gem
    # @return [String] the path of the file, if found.
    # @return [False] if not found
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
