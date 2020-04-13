module Splash
  module Loggers

    class Dual < Splash::Loggers::LoggerTemplate
      include Splash::Config



      def initialize
        super
        @log1 = Splash::Loggers::Cli::new
        @log2 = Splash::Loggers::Daemon::new
      end

      def log(options)
        @log1.log options
        @log2.log options
      end

    end
  end
end
