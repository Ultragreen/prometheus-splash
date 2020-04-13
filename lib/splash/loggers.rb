# coding: utf-8


module Splash
  module Loggers
    include Splash::Config

    @@logger=nil

    def get_logger(options = {})
      logger = (get_config.loggers[:list].include? options[:logger])? options[:logger].to_s : get_config.loggers[:default].to_s
      aclass = "Splash::Loggers::#{logger.capitalize}"
#      begin
        return @@logger = Kernel.const_get(aclass)::new if options[:force]
        return @@logger ||= Kernel.const_get(aclass)::new
#      rescue
#        splash_exit case: :configuration_error, more: "Logger specified inexistant : #{logger}"
#      end
    end


    def change_logger(options = {})
      options[:force] = true
      get_logger(options)
    end



    class LoggerTemplate
      include Splash::Config

      LEVELS = [:debug, :warn, :info, :result, :fatal, :unknown]
      ALIAS = {:flat => :info, :item => :info, :ok => :info, :ko => :info, :trigger => :info,
        :schedule => :info, :arrow => :info, :send => :info,
        :receive => :info, :error => :result, :success => :result }
      LEVELS.each do |method|
        define_method(method) do |message|
            self.log({ :level => method, :message => message})
        end
      end
      ALIAS.keys.each do |method|
        define_method(method) do |message|
            self.log({ :level => method, :message => message})
        end
      end
      def initialize
        self.level = get_config.loggers[:level]


      end


      def log(options)
        level = (ALIAS.keys.include? options[:level])?  ALIAS[options[:level]] : options[:level]
        if @active_levels.include? level then
          puts options[:message]
        end
      end


      def level
        return @active_levels.first
      end

      def level=(level)
        if LEVELS.include? level then
          @active_levels = LEVELS.dup
          @active_levels.shift(LEVELS.index(level))
        else
          raise BadLevel
        end
      end


      private
      def alt(symbol)
        return "=>" if symbol == :arrow
        return '' if symbol == :flat
        return symbol.to_s.upcase
      end

    end

    class BadLevel < Exception; end

  end
end

Dir[File.dirname(__FILE__) + '/loggers/*.rb'].each {|file| require file  }
