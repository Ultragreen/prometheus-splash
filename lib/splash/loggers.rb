# coding: utf-8

# base Splash module
module Splash

  # Loggers namespace
  module Loggers
    include Splash::Config

    @@logger=nil


    # factory for Loggers
    # @param [Hash] options
    # @option options [Symbol] :logger the name of the logger actually in [:cli, :daemon, :dual]
    # @option options [Boolean] :force to force new instance creation (Logger is class variable)
    # @return [SPlash::Loggers::<type>] type is Cli, Dual, Daemon
    def get_logger(options = {})
      logger = (get_config.loggers[:list].include? options[:logger])? options[:logger].to_s : get_config.loggers[:default].to_s
      aclass = "Splash::Loggers::#{logger.capitalize}"
      begin
        return @@logger = Kernel.const_get(aclass)::new if options[:force]
        return @@logger ||= Kernel.const_get(aclass)::new
      rescue
        splash_exit case: :configuration_error, more: "Logger specified inexistant : #{logger}"
      end
    end

    # build a session number
    # @return [String] Session number
    def get_session
      return "#{Time.now.to_i.to_s}#{rand(999)}"
    end


    # wrapper to change logger, call get_logger with force: true
    # @option options [Symbol] :logger the name of the logger actually in [:cli, :daemon, :dual]
    def change_logger(options = {})
      level = get_logger.level
      options[:force] = true
      get_logger(options).level = level
    end

    LEVELS = [:debug, :warn, :info, :result, :fatal, :unknown]
    ALIAS = {:flat => :info, :item => :info, :ok => :info, :ko => :info, :trigger => :info,
      :schedule => :info, :arrow => :info, :send => :info, :call => :info,
      :receive => :info, :error => :result, :success => :result }

      # class template for loggers
    class LoggerTemplate
      include Splash::Config


      LEVELS.each do |method|
        define_method(method) do |message,session = ''|
            self.log({ :level => method, :message => message, :session => session})
        end
      end
      ALIAS.keys.each do |method|
        define_method(method) do |message,session = ''|
            self.log({ :level => method, :message => message, :session => session})
        end
      end

      # constructor
      def initialize
        self.level = get_config.loggers[:level]


      end

      # abstract method for log wrapper
      # @param [Hash] options
      # @option options [Symbol] :level, a valid level in LEVELS or ALIAS
      # @option options [String] :message text
      def log(options)
        level = (ALIAS.keys.include? options[:level])?  ALIAS[options[:level]] : options[:level]
        if @active_levels.include? level then
          puts options[:message]
        end
      end

      # getter for the current level
      # @return [Symbol] level
      def level
        return @active_levels.first
      end

      # virtual setter for level, set the current level
      # @raise a badLevel in case of bad level
      # @param [Symbol] level
      def level=(level)
        if LEVELS.include? level then
          @active_levels = LEVELS.dup
          @active_levels.shift(LEVELS.index(level))
        else
          raise BadLevel
        end
      end


      private
      # mapper for symbol Symbol to String
      # @param [Symbol] symbol
      # @return [String] in upcase, exception :arrow give '=>', :flat give ''
      def alt(symbol)
        return "=>" if symbol == :arrow
        return '' if symbol == :flat
        return symbol.to_s.upcase
      end

    end

    # badLevel Exception
    class BadLevel < Exception; end

  end
end

Dir[File.dirname(__FILE__) + '/loggers/*.rb'].each {|file| require file  }
