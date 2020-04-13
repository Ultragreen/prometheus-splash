# coding: utf-8
module Splash
  module Loggers


    class Daemon < Splash::Loggers::LoggerTemplate



      def initialize
        self.level = get_config.loggers[:level]
        @log_file = get_config.loggers[:daemon][:file]
        @stream = File::open(@log_file, 'a')
        @stream.sync = true
      end


      def log(options)
        level = (ALIAS.keys.include? options[:level])?  ALIAS[options[:level]] : options[:level]
        if @active_levels.include? level then
          @stream.puts "#{alt(options[:level])} #{options[:message]}"
        end
      end

      def close
        @stream.close
      end

    end

  end
end
