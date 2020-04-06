module Splash
  module Constants
    VERSION = "0.0.2"
    CONFIG_FILE = "/etc/splash.yml"
    DAEMON_USER = "root"
    DAEMON_GROUP = "wheel"
    PID_PATH="/var/run"
    TRACE_PATH="/var/run/splash"
    PID_FILE="splash.pid"
    STDOUT_TRACE="stdout.txt"
    STDERR_TRACE="stderr.txt"
    DAEMON_PROCESS_NAME="Splash : daemon."
    AUTHOR="Romain GEORGES"
    EMAIL = "gems@ultragreen.net"
    COPYRIGHT="Ultragreen (c) 2020"
    LICENSE="BSD-2-Clause"
    PROMETHEUS_PUSHGATEWAY_HOST = "localhost"
    PROMETHEUS_PUSHGATEWAY_PORT = "9091"
    EXECUTION_TEMPLATE="/etc/splash_execution_report.tpl"
    TOKENS_LIST = [:date,:cmd_name,:cmd_line,:stdout,:stderr,:desc,:status]
    BACKENDS_STRUCT = { :list => [:file,:redis],
                        :active => :file,
                        :file => { :path => "/var/run/splash" },
                        :redis => {:base => 1, :host: "loclahost", :port: 6379 } }
    BACKENDS_STRUCT = { :list => [:rabbitmq],
                        :active => :rabbitmq,
                        :rabbitmq => :{ :url => 'amqp://localhost/'}



  end
end
