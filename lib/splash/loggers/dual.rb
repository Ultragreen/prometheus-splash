module Splash
  module Loggers

    class Dual #< Splash::Loggers::LoggerTemplate


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

      def initialize
        super
        @log1 = Splash::Loggers::Cli::new
        @log2 = Splash::Loggers::Daemon::new
      end

      def log(options)
        @log1.log options
        @log2.log options
      end
      def level
        @level
      end

      def level=(level)
        @level = level
        @log1.level=level
        @log2.level=level
      end
    end
  end
end
