# coding: utf-8
module Splash
  module Constants
    VERSION = "0.1.1"

    # the path to th config file, not overridable by config
    CONFIG_FILE = "/etc/splash.yml"
    # the default execution trace_path if backend file
    TRACE_PATH="/var/run/splash"


    # default scheduling criteria for log monitoring
    DAEMON_LOGMON_SCHEDULING={ :every => '20s'}
    # the display name of daemon in proc info (ps/top)
    DAEMON_PROCESS_NAME="Splash : daemon."
    # the default pid file path
    DAEMON_PID_PATH="/var/run"
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

    # the default prometheus pushgateway host
    PROMETHEUS_PUSHGATEWAY_HOST = "localhost"
    # the default prometheus pushgateway port
    PROMETHEUS_PUSHGATEWAY_PORT = "9091"

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
                        :rabbitmq => { :url => 'amqp://localhost/'} }



  end
end
