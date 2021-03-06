# coding: utf-8
Dir[File.dirname(__FILE__) + '/config/*.rb'].each {|file| require file  }

# base Splash Module
module Splash

  # Config namespace
  module Config
    include Splash::Helpers
    include Splash::Constants
    include Splash::ConfigUtilities


    class ConfigLinter
      def initialize
        @lints_present = {:logs => [:label, :log, :pattern ],
                          :processes => [:process, :patterns ],
                          :commands => [:name, :desc, :command ]}
        @lints_types = {:logs => {:label => Symbol, :log => String, :pattern => String, :retention => Hash},
                        :processes  => {:process => Symbol, :patterns => Array, :retention => Hash},
                        :commands => {:name => Symbol, :desc => String, :command => String, :schedule => Hash,
                                      :retention => Hash, :on_failure => Symbol, :on_success => Symbol,
                                      :user => String, :delegate_to => Hash}}
      end

      def verify(options ={})
        status = :success
        missings = []
        type_errors = []
        useless = []
        options[:record].each do |key,value|
          useless.push key unless @lints_present[options[:type]].include? key or @lints_types[options[:type]].keys.include? key
          type_errors.push key if @lints_types[options[:type]][key] != value.class and (@lints_present[options[:type]].include? key or @lints_types[options[:type]].keys.include? key)
        end
        @lints_present[options[:type]].each do |item|
          missings.push item unless options[:record].keys.include? item
        end

        status = :failure if (missings.count > 0) or (type_errors.count > 0)
        return {:missings => missings, :type_errors => type_errors, :useless => useless, :status => status}
      end

    end

    # Class to manage configuration in Splash from Splash::Constants override by Yaml CONFIG
    class Configuration < Hash
      include Splash::Constants

      attr_accessor :config_from_file

      # constructor : read config file and map against Constants
      def initialize(config_file=CONFIG_FILE)
        @config_file = config_file
        hash_config_to_default

      end


      def hash_config_to_default
        @config_from_file = readconf @config_file
        self[:version] = VERSION
        self[:author] = "#{AUTHOR} <#{EMAIL}>"
        self[:copyright] = "#{COPYRIGHT} #{LICENSE}"

        self[:prometheus_url] = (@config_from_file[:prometheus][:url])? @config_from_file[:prometheus][:url] : PROMETHEUS_URL
        self[:prometheus_pushgateway_url] = (@config_from_file[:prometheus][:pushgateway])? @config_from_file[:prometheus][:pushgateway] : PROMETHEUS_PUSHGATEWAY_URL
        self[:prometheus_alertmanager_url] = (@config_from_file[:prometheus][:alertmanager])? @config_from_file[:prometheus][:alertmanager] : PROMETHEUS_ALERTMANAGER_URL

        self[:daemon_process_name] = (@config_from_file[:daemon][:process_name])? @config_from_file[:daemon][:process_name] : DAEMON_PROCESS_NAME
        self[:daemon_logmon_scheduling] = (@config_from_file[:daemon][:logmon_scheduling])? @config_from_file[:daemon][:logmon_scheduling] : DAEMON_LOGMON_SCHEDULING
        self[:daemon_metrics_scheduling] = (@config_from_file[:daemon][:metrics_scheduling])? @config_from_file[:daemon][:metrics_scheduling] : DAEMON_METRICS_SCHEDULING
        self[:daemon_procmon_scheduling] = (@config_from_file[:daemon][:procmon_scheduling])? @config_from_file[:daemon][:procmon_scheduling] : DAEMON_PROCMON_SCHEDULING
        self[:daemon_pid_file] = (@config_from_file[:daemon][:files][:pid_file])? @config_from_file[:daemon][:files][:pid_file] : DAEMON_PID_FILE
        self[:daemon_stdout_trace] = (@config_from_file[:daemon][:files][:stdout_trace])? @config_from_file[:daemon][:files][:stdout_trace] : DAEMON_STDOUT_TRACE
        self[:daemon_stderr_trace] = (@config_from_file[:daemon][:files][:stderr_trace])? @config_from_file[:daemon][:files][:stderr_trace] : DAEMON_STDERR_TRACE


        self[:webadmin_port] = (@config_from_file[:webadmin][:port])? @config_from_file[:webadmin][:port] : WEBADMIN_PORT
        self[:webadmin_ip] = (@config_from_file[:webadmin][:ip])? @config_from_file[:webadmin][:ip] : WEBADMIN_IP
        self[:webadmin_proxy] = (@config_from_file[:webadmin][:proxy])? @config_from_file[:webadmin][:proxy] : WEBADMIN_PROXY
        self[:webadmin_process_name] = (@config_from_file[:webadmin][:process_name])? @config_from_file[:webadmin][:process_name] : WEBADMIN_PROCESS_NAME
        self[:webadmin_pid_file] = (@config_from_file[:webadmin][:files][:pid_file])? @config_from_file[:webadmin][:files][:pid_file] : WEBADMIN_PID_FILE
        self[:webadmin_stdout_trace] = (@config_from_file[:webadmin][:files][:stdout_trace])? @config_from_file[:webadmin][:files][:stdout_trace] : WEBADMIN_STDOUT_TRACE
        self[:webadmin_stderr_trace] = (@config_from_file[:webadmin][:files][:stderr_trace])? @config_from_file[:webadmin][:files][:stderr_trace] : WEBADMIN_STDERR_TRACE


        self[:pid_path] = (@config_from_file[:paths][:pid_path])? @config_from_file[:paths][:pid_path] : PID_PATH
        self[:trace_path] = (@config_from_file[:paths][:trace_path])? @config_from_file[:paths][:trace_path] : TRACE_PATH


        self[:execution_template_tokens] = EXECUTION_TEMPLATE_TOKENS_LIST
        self[:execution_template_path] = (@config_from_file[:templates][:execution][:path])? @config_from_file[:templates][:execution][:path] : EXECUTION_TEMPLATE

        self[:transports] = {} ; self[:transports].merge! TRANSPORTS_STRUCT ; self[:transports].merge! @config_from_file[:transports] if @config_from_file[:transports]
        self[:backends] = {} ; self[:backends].merge! BACKENDS_STRUCT ; self[:backends].merge! @config_from_file[:backends] if @config_from_file[:backends]
        self[:loggers] = {} ; self[:loggers].merge! LOGGERS_STRUCT ; self[:loggers].merge! @config_from_file[:loggers] if @config_from_file[:loggers]

        self[:processes] = (@config_from_file[:processes])? @config_from_file[:processes] : {}
        self[:logs] = (@config_from_file[:logs])? @config_from_file[:logs] : {}
        self[:commands] = (@config_from_file[:commands])? @config_from_file[:commands] : {}
        self[:sequences] = (@config_from_file[:sequences])? @config_from_file[:sequences] : {}
        self[:transfers] = (@config_from_file[:transfers])? @config_from_file[:transfers] : {}
      end


      def add_record(options = {})
        @config_from_file = readconf @config_file
        key = options[:key]
        res = ConfigLinter::new.verify(options)
        if res[:status] == :success then
          if @config_from_file[options[:type]].select{|item| item[options[:key]] == options[:record][options[:key]]}.count > 0 then
            return {:status => :already_exist}
          else
            res[:useless].each {|item| options[:record].delete item} if options[:clean]
            @config_from_file[options[:type]].push options[:record]
            writeconf
            hash_config_to_default
            return {:status => :success}
          end
        else
          return res
        end
      end


      def delete_record(options = {})
        @config_from_file = readconf @config_file
        unless @config_from_file[options[:type]].select{|item| item[options[:key]] == options[options[:key]]}.count > 0 then
          return {:status => :not_found}
        else
          @config_from_file[options[:type]].delete_if {|value| options[options[:key]] == value[options[:key]] }
          writeconf
          hash_config_to_default
          return {:status => :success}
        end
      end


      # @!group accessors on configurations Items

      # getter for full Config Hash
      # @return [Hash]
      def full
        return self
      end

      # getter for loggers Hash Config sample
      # @return [Hash]
      def loggers
        return self[:loggers]
      end

      # getter for backends Hash Config sample
      # @return [Hash]
      def backends
        return self[:backends]
      end

      # getter for transports Hash Config sample
      # @return [Hash]
      def transports
        return self[:transports]
      end

      # getter for transfers Hash Config sample
      # @return [Hash]
      def transfers
        return self[:transfers]
      end

      # getter for daemon_logmon_scheduling Hash Config sample
      # @return [Hash]
      def daemon_logmon_scheduling
        return self[:daemon_logmon_scheduling]
      end

      # getter for daemon_procmon_scheduling Hash Config sample
      # @return [Hash]
      def daemon_procmon_scheduling
        return self[:daemon_procmon_scheduling]
      end

      # getter for daemon_metrics_scheduling Hash Config sample
      # @return [Hash]
      def daemon_metrics_scheduling
        return self[:daemon_metrics_scheduling]
      end

      # getter for daemon_process_name Config sample
      # @return [String]
      def daemon_process_name
        return self[:daemon_process_name]
      end


      # getter for daemon_full_pid_path Config sample
      # @return [String]
      def daemon_full_pid_path
        return "#{self[:pid_path]}/#{self[:daemon_pid_file]}"
      end

      # getter for daemon_full_stdout_trace_path Config sample
      # @return [String]
      def daemon_full_stdout_trace_path
        return "#{self[:trace_path]}/#{self[:daemon_stdout_trace]}"
      end

      # getter for daemon_full_stderr_trace_path Config sample
      # @return [String]
      def daemon_full_stderr_trace_path
        return "#{self[:trace_path]}/#{self[:daemon_stderr_trace]}"
      end

      # getter for execution_template_path Hash Config sample
      # @return [String]
      def execution_template_path
        return self[:execution_template_path]
      end

      # getter for execution_template_tokens Hash Config sample
      # @return [Array]
      def execution_template_tokens
        return self[:execution_template_tokens]
      end


      # getter for webadmin_port Hash Config sample
      # @return [Fixnum]
      def webadmin_port
        return self[:webadmin_port]
      end

      # getter for webadmin_ip Hash Config sample
      # @return [String]
      def webadmin_ip
        return self[:webadmin_ip]
      end

      # getter for webadmin_proxy Hash Config sample
      # @return [TrueClass|FalseClass]
      def webadmin_proxy
        return self[:webadmin_proxy]
      end

      # getter for webadmin_process_name Config sample
      # @return [String]
      def webadmin_process_name
        return self[:webadmin_process_name]
      end

      # getter for webadmin_full_pid_path Config sample
      # @return [String]
      def webadmin_full_pid_path
        return "#{self[:pid_path]}/#{self[:webadmin_pid_file]}"
      end

      # getter for webadmin_full_stdout_trace_path Config sample
      # @return [String]
      def webadmin_full_stdout_trace_path
        return "#{self[:trace_path]}/#{self[:webadmin_stdout_trace]}"
      end

      # getter for webadmin_full_stderr_trace_path Config sample
      # @return [String]
      def webadmin_full_stderr_trace_path
        return "#{self[:trace_path]}/#{self[:webadmin_stderr_trace]}"
      end




      # getter for logs Hash Config sample
      # @return [Hash]
      def logs
        return self[:logs]
      end

      # getter for commands Hash Config sample
      # @return [Hash]
      def commands
        return self[:commands]
      end

      # getter for processes Hash Config sample
      # @return [Hash]
      def processes
        return self[:processes]
      end

      # getter for sequences Hash Config sample
      # @return [Hash]
      def sequences
        return self[:sequences]
      end

      # getter for author Config sample
      # @return [String]
      def author
        return self[:author]
      end

      # getter for copyright Config sample
      # @return [String]
      def copyright
        return self[:copyright]
      end

      # getter for version Config sample
      # @return [String]
      def version
        return self[:version]
      end





      # getter for prometheus_pushgateway_url Config sample
      # @return [String]
      def prometheus_pushgateway_url
        return self[:prometheus_pushgateway_url]
      end

      # getter for prometheus_alertmanager_url Config sample
      # @return [String]
      def prometheus_alertmanager_url
        return self[:prometheus_alertmanager_url]
      end


      # getter for prometheus_url Config sample
      # @return [String]
      def prometheus_url
        return self[:prometheus_url]
      end

      # @!endgroup

      private

      # read config file
      # @param [String] file default from CONFIG_FILE
      # @return [Hash] The config global Hash from YAML
      def readconf(file = CONFIG_FILE)
        return YAML.load_file(file)[:splash]
      end

      # write config to file from @config_from_file
      # @param [String] file default from CONFIG_FILE
      # @return [Bool] if ok
      def writeconf(file = CONFIG_FILE)
        File.open(file,"w") do |f|
          data = {}
          data[:splash] = @config_from_file
          f.write(data.to_yaml)
        end
      end

    end



    @@config=nil

    # factory of Configuration Class instance
    # @param [String] config_file the path of the YAML Config file
    # @return [SPlash::Config::Configuration]
    def get_config(config_file=CONFIG_FILE)
      return @@config ||= Configuration::new(config_file)
    end

    # reset of Configuration Class instance
    # @param [String] config_file the path of the YAML Config file
    # @return [SPlash::Config::Configuration]
    def rehash_config(config_file=CONFIG_FILE)
      return @@config = Configuration::new(config_file)
    end


  end
end
