# coding: utf-8

module Splash
  module Loggers

    class Cli
      include Splash::Config

      def initialize
        @levels = [:debug, :info, :warn, :error, :fatal, :unkown]
        self.level = get_config.loggers[:level]
      end

      def level
        return @active_levels.first
      end

      def level=(level)
        if @levels.include? level then
          @active_levels = @levels
          @active_levels.shift(@levels.index(level))
        else
          raise BadLevel
        end
      end


      def check_unicode_term
        if ENV.values_at("LC_ALL","LC_CTYPE","LANG").compact.first.include?("UTF-8") and ENV.values_at('TERM').first.include? "xterm" then
          return true
        else
          return false
        end
      end
    end

    class BadLevel < Exception; end

  end
end
