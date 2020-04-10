# coding: utf-8
module Splash
  module Dependencies


    # Internal Ruby
    require 'open3'
    require 'date'
    require 'socket'
    require 'yaml'
    require 'thread'
    require 'fileutils'
    require 'etc'
    require 'forwardable'



    # Rubygems
    begin
      require 'prometheus/client'
      require 'prometheus/client/push'
      require 'thor'
      require 'bunny'
      require 'rufus-scheduler'
      require 'tty-markdown'
      require 'tty-pager'
      require "redis"

    rescue Gem::GemNotFoundException
      $stderr.puts "Loadind error, it's like you try to run Splash, with a lake of dependencies."
      $stderr.puts "If you run on RVM, please run with rvmsudo and not with sudo."
      $stderr.puts "If problem is percistant, please, proceed to new install and Setup."
    end


    # Splash
    require 'splash/constants'
    require 'splash/helpers'
    require 'splash/config'
    require 'splash/exiter'
    require 'splash/templates'
    require 'splash/backends'
    require 'splash/transports'

    require 'splash/commands'
    require 'splash/logs'
    require 'splash/orchestrator'
    require 'splash/controller'

  end
end
