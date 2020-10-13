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
    require 'json'
    require 'uri'





    # Rubygems
    begin
      require 'net/ssh'
      require 'net/scp'
      require 'tty-prompt'
      require 'prometheus/client'
      require 'prometheus/client/push'
      require 'thor'
      require 'bunny'
      require 'rufus-scheduler'
      require 'tty-markdown'
      require 'tty-pager'
      require 'colorize'
      require "redis"
      require 'ps-ruby'
      require 'sinatra/base'
      require 'thin'
      require 'slim'
      require 'rest-client'
      require 'kramdown'
      require 'rack/reverse_proxy'


    rescue Gem::GemNotFoundException
      $stderr.puts "Loadind error, it's like you try to run Splash, with a lake of dependencies."
      $stderr.puts "If you run on RVM, please run with rvmsudo and not with sudo."
      $stderr.puts "If problem is percistant, please, proceed to new install and Setup."
    end


    # Splash
    require 'splash/constants'
    require 'splash/helpers'
    require 'splash/config'
    require 'splash/loggers'
    require 'splash/exiter'
    require 'splash/templates'
    require 'splash/backends'
    require 'splash/transports'


    require 'splash/commands'
    require 'splash/sequences'
    require 'splash/logs'
    require 'splash/processes'
    require 'splash/transferts'

    require 'splash/daemon'
    require 'splash/webadmin'


  end
end
