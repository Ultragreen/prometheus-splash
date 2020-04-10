# coding: utf-8
Dir[File.dirname(__FILE__) + '/cli/*.rb'].each {|file| require file  }

class CLI < Thor
  def self.exit_on_failure?
    true
  end

  include CLISplash
  desc "commands SUBCOMMAND ...ARGS", "Managing commands/batchs supervision"
  subcommand "commands", Commands
  desc "logs SUBCOMMAND ...ARGS", "Managing Files/Logs supervision"
  subcommand "logs", Logs
  desc "daemon SUBCOMMAND ...ARGS", "Logs monitor daemon contoller"
  subcommand "daemon", CLIController
  desc "config SUBCOMMAND ...ARGS", "config tools for Splash"
  subcommand "config", Config
  desc "documentation SUBCOMMAND ...ARGS", "Documentation for Splash"
  subcommand "documentation", Documentation
end
