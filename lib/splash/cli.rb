# coding: utf-8
Dir[File.dirname(__FILE__) + '/cli/*.rb'].each {|file| require file  }

# The CLI Command structure for Thor
class CLI < Thor

  # callback for managing ARGV errors
  def self.exit_on_failure?
    true
  end

  # Constructor override to manage debug, colors and emoji options for logger
  def initialize(*args)
    super
    log = get_logger
    options[:colors.to_s]
    log.level = :debug if options[:debug]
    log.emoji  = options[:emoji.to_s]
    log.color  = options[:colors.to_s]
    log.debug  "DEBUG activated" if options[:debug]
  end

  class_option :quiet, :desc => "Quiet mode, limit output to :fatal", :aliases => "-q", :type => :boolean
  class_option :emoji, :desc => "Display Emoji", :type => :boolean, :default => true
  class_option :colors, :desc => "Display colors", :type => :boolean, :default => true
  class_option :debug, :desc => "Set log level to :debug", :aliases => "-d", :type => :boolean


  include CLISplash
  desc "commands SUBCOMMAND ...ARGS", "Managing commands/batchs supervision & orchestration"
  subcommand "commands", Commands
  desc "logs SUBCOMMAND ...ARGS", "Managing Files/Logs supervision"
  subcommand "logs", Logs
  desc "processes SUBCOMMAND ...ARGS", "Managing processes supervision"
  subcommand "processes", Processes
  desc "daemon SUBCOMMAND ...ARGS", "Splash daemon controller"
  subcommand "daemon", CLIController
  desc "config SUBCOMMAND ...ARGS", "Config tools for Splash"
  subcommand "config", Config
  desc "documentation SUBCOMMAND ...ARGS", "Documentation for Splash"
  subcommand "documentation", Documentation
  desc "webadmin SUBCOMMAND ...ARGS", "Splash Webadmin daemon controller"
  subcommand "documentation", WebAdmin


end
