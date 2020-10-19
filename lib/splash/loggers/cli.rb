# coding: utf-8

# base Splash module
module Splash

  # Splash Loggers module
  module Loggers

    # Cli specific logger
    class Cli < Splash::Loggers::LoggerTemplate

      include Splash::Config
      include Splash::Helpers

      # mapping of UTf-8 emoji for log levels or alias
      EMOJI =  { :unknown => "\u{1F4A5}",
                 :fatal => "\u{26D4}",
                 :error => "\u{1F6AB}",
                 :ko => "\u{1F44E}",
                 :warn => "\u{26A0}",
                 :info => "\u{2139}",
                 :item => " \u{1F539}",
                 :arrow => "  \u{27A1}",
                 :schedule => "\u{23F1}",
                 :trigger => "\u{23F0}",
                 :send => "\u{1F4E4}",
                 :receive => "\u{1F4E5}",
                 :ok => "\u{1F44D}",
                 :success => "\u{1F4AA}",
                 :debug => "\u{1F41B}"}

      # mapping of colors for log levels or alias
      COLORS = { :unknown => :red,
                 :fatal => :red,
                 :error => :red,
                 :ko => :yellow,
                 :warn => :yellow,
                 :item => :white,
                 :arrow => :white,
                 :send => :white,
                 :schedule => :white,
                 :trigger => :white,
                 :receive => :white,
                 :info => :cyan,
                 :ok => :green,
                 :success => :green,
                 :debug => :magenta}


      # log wrapper
      # @param [Hash] options
      # @option options [Symbol] :level defined in Splash::Loggers::LEVEL or Splash::Loggers::ALIAS
      # @option options [String] :message
      # display formatted string to STDOUT
      def log(options)
        level = (ALIAS.keys.include? options[:level])?  ALIAS[options[:level]] : options[:level]
        if @active_levels.include? level then
          if options[:level] == :flat then
            puts options[:message]
          else
            String.disable_colorization = !get_config.loggers[:cli][:color]
            emoji = get_config.loggers[:cli][:emoji]
            emoji = check_unicode_term if emoji
            if emoji then
              display = "#{EMOJI[options[:level]]} #{options[:message]}"
            else
              display = "#{alt(options[:level])} #{options[:message]}"
            end
            puts display.colorize(COLORS[options[:level]])
          end
        end
      end

      # setter in configuration for emoji display
      # @param [Boolean] status
      def emoji=(status)
        get_config.loggers[:cli][:emoji] = status
      end

      # setter in configuration for color display
      # @param [Boolean] status
      def color=(status)
        get_config.loggers[:cli][:color] = status
      end



    end

  end
end
