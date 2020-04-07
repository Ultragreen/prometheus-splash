module Splash
  module Constants
    VERSION = "0.0.3"

    CONFIG_FILE = "/etc/splash.yml"
    TRACE_PATH="/var/run/splash"

    DAEMON_LOGMON_SCHEDULING={ :every => '20s'}
    DAEMON_PROCESS_NAME="Splash : daemon."
    DAEMON_PID_PATH="/var/run"
    DAEMON_PID_FILE="splash.pid"
    DAEMON_STDOUT_TRACE="stdout.txt"
    DAEMON_STDERR_TRACE="stderr.txt"

    AUTHOR="Romain GEORGES"
    EMAIL = "gems@ultragreen.net"
    COPYRIGHT="Ultragreen (c) 2020"
    LICENSE="BSD-2-Clause"

    PROMETHEUS_PUSHGATEWAY_HOST = "localhost"
    PROMETHEUS_PUSHGATEWAY_PORT = "9091"

    EXECUTION_TEMPLATE="/etc/splash_execution_report.tpl"
    EXECUTION_TEMPLATE_TOKENS_LIST = [:end_date,:start_date,:cmd_name,:cmd_line,:stdout,:stderr,:desc,:status,:exec_time]

    BACKENDS_STRUCT = { :list => [:file,:redis],
                        :stores => { :execution_trace => { :type => :file, :path => "/var/run/splash" }}}
    TRANSPORTS_STRUCT = { :list => [:rabbitmq],
                        :active => :rabbitmq,
                        :rabbitmq => { :url => 'amqp://localhost/'} }



  end
end
