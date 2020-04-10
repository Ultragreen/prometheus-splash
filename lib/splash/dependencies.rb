module Splash
  module Dependencies


    # Internal Ruby
    require 'socket'
    require 'yaml'
    require 'thread'


    # Rubygems
    begin
      require 'prometheus/client'
      require 'prometheus/client/push'
      require 'thor'
      require 'rufus-scheduler'
      require 'tty-markdown'
      require 'tty-pager'

    rescue Gem::GemNotFoundException
      $stderr.puts "Loadind error, it's like you try to run Splash, with a lake of dependencies."
      $stderr.puts "If you run on RVM, please run with rvmsudo and not with sudo."
      $stderr.puts "If problem is percistant, please, proceed to new install and Setup."
    end


    # Splash 
    require 'splash/constants'
    require 'splash/helpers'
    require 'splash/config'
    require 'splash/templates'
    require 'splash/backends'
    require 'splash/transports'

    require 'splash/commands'
    require 'splash/logs'
    require 'splash/orchestrator'
    require 'splash/controller'

  end
end
