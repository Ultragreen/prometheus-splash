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

      def close
        @stream.close
      end



    end

  end
end
