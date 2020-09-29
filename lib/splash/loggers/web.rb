# coding: utf-8

# base Splash module
module Splash

  # Splash Loggers module
  module Loggers

    # Web specific logger
    class Web < Splash::Loggers::LoggerTemplate


      # contructor, open log file
      # @return [Splash::Loggers::Web]
      def initialize
        self.level = get_config.loggers[:level]
        @log_file = get_config.loggers[:web][:file]
        @stream = File::open(@log_file, 'a')
        @stream.sync = true
      end

      # log wrapper
      # @param [Hash] options
      # @option options [Symbol] :level defined in Splash::Loggers::LEVEL or Splash::Loggers::ALIAS
      # @option options [String] :message
      # @option options [String] :session a session number
      # write formatted string to log file
      def log(options)
        pid = Process.pid.to_s
        date = DateTime.now.to_s
        level = (ALIAS.keys.include? options[:level])?  ALIAS[options[:level]] : options[:level]
        if @active_levels.include? level then
          unless options[:session].empty? then
            @stream.puts "[#{date}] (#{pid}) (#{options[:session]}) #{alt(options[:level])} : #{options[:message]}"
          else
            @stream.puts "[#{date}] (#{pid}) #{alt(options[:level])} : #{options[:message]}"
          end
        end
      end

      # close log file descriptor
      def close
        @stream.close
      end



    end

  end
end
