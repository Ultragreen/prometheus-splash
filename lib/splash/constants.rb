# coding: utf-8

# base Splash module / namespace
module Splash

  # Constants namespace
  module Constants

    # Current splash version
    VERSION = "0.9.1"
    # the path to th config file, not overridable by config
    CONFIG_FILE = "/etc/splash.yml"
    # the default execution trace_path if backend file
    TRACE_PATH="/var/run/splash"
    # the default pid file path
    PID_PATH="/var/run"


    # default scheduling criteria for log monitoring
    DAEMON_LOGMON_SCHEDULING={ :every => '20s'}
    # default scheduling criteria for  metrics notifications
    DAEMON_METRICS_SCHEDULING={ :every => '15s'}
    # default scheduling criteria for process monitoring
    DAEMON_PROCMON_SCHEDULING={ :every => '20s'}

    # the display name of daemon in proc info (ps/top)
    DAEMON_PROCESS_NAME="Splash : daemon."
    # the default pid file name
    DAEMON_PID_FILE="splash.pid"
    # the default sdtout trace file
    DAEMON_STDOUT_TRACE="stdout.txt"
    # the default sdterr trace file
    DAEMON_STDERR_TRACE="stderr.txt"

    # the Author name
    AUTHOR="Romain GEORGES"
    # the maintainer mail
    EMAIL = "gems@ultragreen.net"
    # legal Copyright (c) 2020 Copyright Utragreen All Rights Reserved.
    COPYRIGHT="Ultragreen (c) 2020"
    # type of licence
    LICENSE="BSD-2-Clause"

    # the default prometheus pushgateway URL
    PROMETHEUS_PUSHGATEWAY_URL = 'http://localhost:9091/'

    # the default prometheus Alertmanager URL
    PROMETHEUS_ALERTMANAGER_URL = 'http://localhost:9092/'

    # the default prometheus URL
    PROMETHEUS_URL = "http://localhost:9090/"

    # the default path fo execution report template
    EXECUTION_TEMPLATE="/etc/splash_execution_report.tpl"

    # the list of authorized tokens for template, carefull override,
    EXECUTION_TEMPLATE_TOKENS_LIST = [:end_date,:start_date,:cmd_name,:cmd_line,:stdout,:stderr,:desc,:status,:exec_time]

    # backends default settings
    BACKENDS_STRUCT = { :list => [:file,:redis],
                        :stores => { :execution_trace => { :type => :file, :path => "/var/run/splash" }}}
    # transports default settings
    TRANSPORTS_STRUCT = { :list => [:rabbitmq],
                          :active => :rabbitmq,
                          :rabbitmq => { :port => 5672, :host => "localhost", :vhost => '/'} }

    # loggers default settings
    LOGGERS_STRUCT = { :list => [:cli,:daemon, :dual, :web],
                       :default => :cli,
                       :level => :info,
                       :daemon => {:file => '/var/log/splash.log'},
                       :web => {:file => '/var/log/splash_web.log'},
                       :cli => {:color => true, :emoji => true }  }

    WEBADMIN_IP = "127.0.0.1"
    WEBADMIN_PORT = "9234"
    WEBADMIN_PROXY = false
    # the display name of daemon in proc info (ps/top)
    WEBADMIN_PROCESS_NAME="Splash : WebAdmin."
    # the default pid file path
    WEBADMIN_PID_PATH="/var/run"
    # the default pid file name
    WEBADMIN_PID_FILE="splash.pid"
    # the default sdtout trace file
    WEBADMIN_STDOUT_TRACE="stdout.txt"
    # the default sdterr trace file
    WEBADMIN_STDERR_TRACE="stderr.txt"

    # default retention for trace
    DEFAULT_RETENTION=1

  end
end
