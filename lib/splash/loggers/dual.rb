# coding: utf-8

# base Splash module
module Splash

  # Splash Loggers module
  module Loggers

    # Dual multiplexer specific logger
    # log against CLi and Daemon
    class Dual #< Splash::Loggers::LoggerTemplate


      include Splash::Config

      # build levels and alias forwarders
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

      # Constructor build two attributes for each loggers : Cli, Daemon
      def initialize
        super
        @log1 = Splash::Loggers::Cli::new
        @log2 = Splash::Loggers::Daemon::new
      end

      def log(options)
        @log1.log options
        @log2.log options
      end

      # getter for root level
      # @return [Symbol] a level
      def level
        @level
      end

      # setter for global level, both Cli and Daemon
      # @param [Symbol] level a level in Splash::Loggers::LEVELS or Splash::Loggers::ALIAS
      def level=(level)
        @level = level
        @log1.level=level
        @log2.level=level
      end
    end
  end
end
