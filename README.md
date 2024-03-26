# Splash

![Splash logo](assets/images/logo_splash_reduce.png) _Orchestration and Supervision made easy_

SPLASH is **Supervision with Prometheus of Logs and Asynchronous tasks orchestration for Services or Hosts**

* Author : Romain GEORGES
* COPYright : BSD-2-Clause (c) 2020 Ultragreen Software
* Web : http://www.ultragreen.net
* Github : https://github.com/Ultragreen/prometheus-splash
* Rubygems : https://rubygems.org/gems/prometheus-splash
* DOC yardoc : https://www.rubydoc.info/gems/prometheus-splash/0.9.1

Prometheus Logs and Batchs supervision over PushGateway

[![GitHub version](https://badge.fury.io/gh/Ultragreen%2Fprometheus-splash.svg)](https://badge.fury.io/gh/Ultragreen%2Fprometheus-splash)
![Ruby](https://github.com/Ultragreen/prometheus-splash/workflows/Ruby/badge.svg)
[![Gem Version](https://badge.fury.io/rb/prometheus-splash.svg)](https://badge.fury.io/rb/prometheus-splash)

## Design

![Splash Design](assets/images/splash_design.png)

## Preconfiguration

You need a Prometheus PushGateway operational, if the service not run on localhost:9091,
See Prometheus server Configuration chapter to precise it in the configuration

You need Ruby on the server you want to run Splash
Splash is succesfully tested with Ruby 2.7.0, but it should works correctly with all Ruby 2.X versions.

On Ubuntu :

    # apt install ruby ruby-dev

In some use case, Splash also require some other components :

- Redis
- RabbitMQ

It's not strictly required, Redis is a real option for backend; you could configure backend to flat file, but
RabbitMQ is required by the Splash Daemon when using host2host commands/sequence execution.

Redis, is usefull when you need a centralized Splash management.

On Ubuntu :

    # apt install redis-server rabbimq-server

See Backends Configuration  and Transports Configuration to specify this services configurations


## Installation


Install with gem command :

    $ gem install prometheus-splash


## Configuration

As root or with rvmsudo, if you use RVM.

    # splash config setup              
    Splash -> setup :
    * Installing Configuration file : /etc/splash.yml : [OK]
    👍 Splash Initialisation
    👍 Installing template file : /etc/splash_execution_report.tpl
    👍 Creating/Checking pid file path : /var/run/splash
    👍 Creating/Checking trace file path : /var/run/splash/traces :
    💪 Splash Setup terminated successfully

*NOTE : you can just type 'splash' withou any arguments, for the first setup because, Splash come with an automatic recovery mode, when configuration file is missing, run at the very beginnning of his the execution*     

*WARNING : if you have already configured Splash, running this command without --preserve flag, RESET the Splash Configuration.*


As root, edit /etc/splash.conf and adapt Prometheus Pushgateway Configuration :

    # vi /etc/splash.yml
    [..]
      :prometheus:
        :pushgateway: 'http://localhost:9091'
        :url: 'http://localhost:9090'
        :alertmanager: 'http://localhost:9093'

    [..]


If you have already setup, you could use --preserve option to keep your active configuration and report file on place
This is usefull for automatique Idempotent installation like with Ansible :

    # splash conf set --preserve


### Sanitycheck

As root or with rvmsudo, if you use RVM.

    # splash conf san
    ℹ Splash -> sanitycheck :
    👍 Config file : /etc/splash.yml
    👍 PID Path : /var/run/splash
    👍 Trace Path : /var/run/splash/traces  
    👍 Prometheus PushGateway Service running
    💪 Splash Sanitycheck terminated successfully

*WARNING* : setup or Sanitycheck could precises errors if path defined in configuration is *Symbolic links*, type :mode.
But it's not a problem for Splash to be operational.

For file/folders if problems is detected, it could be such as :

- :mode : UNIX rights errors
- :owner : UNIX file owner errors
- :group : UNIX file group errors
- :inexistant : file/folder is missing

### getting current VERSION

run :

    $ splash config version
    ℹ Splash version : 0.8.2, Author : Romain GEORGES <gems@ultragreen.net>
    ℹ Ultragreen (c) 2020 BSD-2-Clause


## Usage

### Logs monitoring

#### Edit your configuration


In the /etc/splash.yml, you need to adapt default config to monitor your logs.

    # vi /etc/splash.yml
    [..]
    ### configuration of monitored logs
      :logs:
        - :label: :a_label
          :log: /a/log/path.log
          :pattern: <regexp pattern>
          :retention:
            :hours: 10
        - :label: :an_other_label
          :log: /an/other/log/path.log
          :pattern: <regexp pattern>
          :retention:
            :days: 1
        - <etc...>
    [..]

Config for log is a YAML list of Hash, with keys :

- :label : a Symbol like ':xxxxxx' used in Splash internaly to identify logs records
- :log : a log absolut paths
- :pattern : a regular expression splash need to detect
- :retention : a hash with keys like (:days or :hours) and a periode in value

#### Prerequisite

To ensure you have the default configuration values run as root :

    # splash conf set

*INFO* : comamnds must be reduce with the Thor completion facilities

To see all monitoring commands with Splash, run :

    # splash logs

or

    # slash logs help
    Commands:
      splash logs analyse         # analyze logs defined in Splash config
      splash logs help [COMMAND]  # Describe subcommands or one specific subcommand
      splash logs history LABEL   # show logs monitoring history
      splash logs list            # List all Splash configured logs monitoring
      splash logs monitor         # monitor logs defined in Splash config
      splash logs show LOG        # show Splash configured log monitoring for LOG

*Typicallly, the way work with all Splash commands or subcommands*



#### Run a first test

Verify /tmp/test and /tmp/test2 not existence

    # rm /tmp/test /tmp/test2

Verify configured logs :

    # splash logs list
    ℹ Splash configured log monitoring :
      🔹 log monitor : /tmp/test label : log_app_1
      🔹 log monitor : /tmp/test2 label : log_app_2

You could run list commands with --detail option , verify it with :

    # splash command subcommand help

like :

    # splash logs list --detail
    ℹ Splash configured log monitoring :
      🔹 log monitor : /tmp/test label : log_app_1
        ➡ pattern : /ERROR/
      🔹 log monitor : /tmp/test2 label : log_app_2
        ➡ pattern : /ERROR/


You cloud view a specific logs record detail with :

    # splash logs show /tmp/test
    ℹ Splash log monitor : /tmp/test
    🔹 pattern : /ERROR/
    🔹 label : log_app_1

*this command Work with a logname or the label*

Run a first analyse, you would see :

    # splash logs analyse
    ℹ SPlash Configured log monitors :
    👎 Log : /tmp/test with label : log_app_1 : missing !
      🔹 Detected pattern : ERROR
    👎 Log : /tmp/test2 with label : log_app_2 : missing !
      🔹 Detected pattern : ERROR
    🚫 Global status : some error found

Create empty Files, or without ERROR string in.

    # echo 'foo' > /tmp/test
    # touch /tmp/test2

Re-run analyse :

    # splash log an
    ℹ SPlash Configured log monitors :
    👍 Log : /tmp/test with label : log_app_1 : no errors
      🔹 Detected pattern : ERROR
      🔹 Nb lines = 1
    👍 Log : /tmp/test2 with label : log_app_2 : no errors
      🔹 Detected pattern : ERROR
      🔹 Nb lines = 0
    👍 Global status : no error found

It's alright, log monitoring work fine.

#### Send metrics to Prometheus gateway

Splash is made to run a specific daemon to do this job, but you could do one time, with :

    # splash logs monitor
    ℹ Sending metrics to Prometheus Pushgateway
    👍 Sending metrics for log /tmp/test to Prometheus Pushgateway
    👍 Sending metrics for log /tmp/test2 to Prometheus Pushgateway

if Prometheus Gateway is not running or misconfigured, you could see :

    ⛔ Splash Service dependence missing : Prometheus Notification not send.

Otherwise Prometheus PushGateway have received the metrics :


- *logerrors*, Prometheus Gauge : with label: <the logname> and job: 'Splash'
  => description : SPLASH metric log error'
  => content :<nb match> the number of pattern matching for the log

- *logmissing*, Prometheus Gauge : with label: <the logname> and job: 'Splash'
  => description : SPLASH metric log missing'
  => content :0 if log exist, 1 if log missing

- *loglines*, Prometheus Gauge : with label: <the logname> and job: 'Splash'
  => description : SPLASH metric log line numbers'
  => content :0 if log missing, <nb lines in the log> the number of lines in the logs

#### See it in Prometheus PushGateway

visit http://<prometheus_pushgateway_host>:<prometheus_pushgateway_port>/

![prom PG logs](assets/images/prom_pg_logs.png)

![prom PG details logs](assets/images/detail_prom_splash.png)


### Commands Orchestration, running and monitoring

#### List of commands

To see all the commands in the 'commands' submenu :

    $ splash commands help

    $ splash commands                           
    Commands:
      splash commands execute NAME                    # run for command/sequence or ack result
      splash commands getreportlist                   # list all executions report results
      splash commands help [COMMAND]                  # Describe subcommands or one specific subcommand
      splash commands history LABEL                   # show commands executions history
      splash commands lastrun COMMAND                 # Show last running result for specific configured command COMMAND
      splash commands list                            # Show configured commands
      splash commands onerun COMMAND -D, --date=DATE  # Show running result for specific configured command COMMAND
      splash commands schedule NAME                   # Schedule excution of command on Splash daemon
      splash commands show COMMAND                    # Show specific configured command COMMAND
      splash commands treeview                        # Show commands sequence tree

#### Prepare test with default configuration

Commands or Commands Sequences must be defined in the main configuration file '/etc/splash.yml'

Command name must be Ruby Symbols, so in the YAML file, it must look like :

    :xxxxxx:

_with x in the following list [A-Za-z_0-9]_


*Exemple* in default configuration :

    ### configuration of commands and scheduling
      :commands:
        :id_root:
          :desc: run id command on root
          :command: id root

        :true_test:
          :desc: "test command returning true : 0"
          :command: "true"
          :schedule:
            :every: "1h"
          :on_failure: :ls_slash_tmp
          :on_success: :pwd

        :false_test:
          :desc: "test command returning false > 0"
          :command: "false"
          :schedule:
            :every: "1h"
          :on_failure: :ls_slash_tmp
          :on_success: :pwd

        :ls_slash_tmp:
          :desc: list file in /tmp
          :command: ls -al /tmp
          :user: daemon
          :on_success: :echo1

        :pwd:
          :desc: run pwd
          :command: pwd
          :on_success: :echo1
          :on_failure: :echo2

        :echo1:
        :desc: echo 'foo'
        :command: echo foo
        :on_failure: :echo3

      :echo2:
        :desc: echo 'bar'
        :command: echo bar

      :echo3:
        :desc: echo 'been'
        :command: echo been

A configuration block for commands must include :

* *key* : a name as Symbol (:xxxxxx)
* *values* : (hash)
  * :desc : a brief Description
  * :command : the full command line

may include :

* :user: the userneme to use to run the command
* :on_failure: the name of an other defined command, to, execute if exit_code > 0
* :on_success: the name of an other defined command, to, execute if exit_code = 0
* :schedule:  (Hash) a scheduling for daemon, after in this documentation, it support :
  * :every: "<timing>" ex: "1s", "3m", "2h"
  * :at: "<date/time>" ex: "2030/12/12 23:30:00"
  * :cron: * * * * * a cron format
* delegate_to: (Hash) a Slash delagation
  * :host: the hostname of an other Confiugured Splash Node.
  * :remote_command: a command defined in the remote Splash node Configuration

_Remarque_ : Command name, as precise earlier in this documentation is Ruby Symbols ':xxxxx'.
In YAML as a Hash key : ':xxxxxx: ', but as a value _':xxxxx'_, so the synthaxe for callbacks :

    :on_success: :xxxxxx
    :on_failure: :xxxxxx

It's the same for :remote_command

[Rufus Scheduler Doc](https://github.com/jmettraux/rufus-scheduler)

if you want to inject default configuration, again as root :

  # splash conf set


#### listing the defined Commands

You could list the defined commands, in your case :

    $ splash commands list
    ℹ Splash configured commands :
    🔹 id_root
    🔹 true_test
    🔹 false_test
    🔹 ls_slash_tmp
    🔹 pwd
    🔹 echo1
    🔹 echo2
    🔹 echo3
    🔹 rand_sleep_5
    🔹 test_remote_call


#### Show specific commands

You could show a specific command :

    $ splash com show pwd
    ℹ Splash command : pwd
    🔹 command line : 'pwd'
    🔹 command description : 'run pwd'
    🔹 command failure callback : 'echo2'
    🔹 command success callback : 'echo1'


#### View Sequence execution for commands

You could trace execution sequence for a commands as a tree, with :

    # splash com treeview
    ℹ Command : true_test
    * on failure => ls_slash_tmp
      * on success => echo1
        * on failure => echo3
    * on success => pwd
      * on failure => echo2
      * on success => echo1
        * on failure => echo3

In your sample, in all case :
- :true_test return 0
- :pwd return 0
- :echo1 return 0

commands execution sequence will be :

:true_test => :pwd => :echo1

:ls_slash_tmp, :echo2 and :echo3 will be never executed.

#### Executing a standalone command :

Running a standalone command with ONLY as root

    # splash com execute echo1
    ℹ Executing command : 'echo1'
      🔹Tracefull execution
    👍 Command executed
      ➡ exitcode 0
    👍 Sending metrics to Prometheus Pushgateway


This command :

1. Execute command line defined in command 'echo1' defined in  configurations
2. Trace information in a execution report :
  - :start_date  the complete date time of execution start.
  - :end_date  the complete date time of execution end.
  - :cmd_name the name of the command
  - :cmd_line the complete command line executed
  - :stdout STDOUT of the command
  - :stderr STDERR of the command
  - :desc the description of the command
  - :status : PID and exit_code of the command
  - :exec_time : the timing of the command
3. Notify Prometheus

There is some usefull modifiers for this command :

    --no-trace : prevent Splash to write report for this execution in configured backend
    --no-notify : prevent Splash to nofify Prometheus PushGateway metric (see later in this documentation)
    --no-callback : never execute callback (see it after)



#### Executing a sequence of callback Commands

Splash allow execution of callback (:on_failure, :on_success), you have already see it in config sample.
In our example, we have see :true_test have a execution sequence, we're going to test this, as root :

    # splash com exe true_test
    ℹ Executing command : 'true_test'
      🔹 Tracefull execution
    👍 Command executed
      ➡ exitcode 0
    👍 Sending metrics to Prometheus Pushgateway
      🔹 On success callback : pwd
    ℹ Executing command : 'pwd'
      🔹 Tracefull execution
    👍 Command executed
      ➡ exitcode 0
    👍 Sending metrics to Prometheus Pushgateway
      🔹 On success callback : echo1
    ℹ Executing command : 'echo1'
      🔹 Tracefull execution
    👍 Command executed
      ➡ exitcode 0
    👍 Sending metrics to Prometheus Pushgateway


We could verify the sequence determined with lastrun command.

If you want to prevent callback execution, as root :

      # splash com exe true_test --no-callback
      ℹ Executing command : 'true_test'
        🔹 Tracefull execution
      👍 Command executed
        ➡ exitcode 0
      👍 Sending metrics to Prometheus Pushgateway
        🔹 Without callbacks sequences

#### Display the last execution trace for a command

If you want to view the last execution trace for  commande, (only if executed with --trace : default)

    # splash com lastrun pwd
    ℹ Splash command pwd previous execution report:

    Command Execution report
    ========================

    Date START: 2020-10-28T13:38:36+01:00
    Date END: 2020-10-28T13:38:36+01:00
    Command : pwd
    full command line : pwd
    Description : run pwd
    errorcode : pid 10958 exit 0
    Execution time (sec) : 0.00737092

    STDOUT:
    -------

    /home/xxx/prometheus-splash



    STDERR:
    -------




Lastrun could receive the --hostname option to get the execution report of command


### Advanced  Configuration

#### Backend configuration

For the moment Splash come with two types of backend :
- :file if you would a standalone splash Usage
- :redis if you want a distributed Splash usage

backend are usable for :

- execution trace
- transfers_trace
- logs_trace
- process_trace

##### File backend

The file backend is very simple to use :

Edit /etc/splash.yml, as root :

    # vi /etc/splash.yml
    [...]
    :backends:
      :stores:
        :execution_trace:
            :type: :file
            :path: /var/run/splash
    [...]

- :type must be :file
- :path should be set to the dedicated executions traces files path (default : /var/run/splash )

##### Redis backend

A little bit more complicated for Redis :

Edit /etc/splash.yml, as root :

    # vi /etc/splash.yml
    [...]
    :backends:
      :stores:
        :execution_trace:
          :type: :redis
          :host: localhost
          :port: 6379
          #:auth: "mykey"
          :base: 1
    [...]

- :type must be :redis
- :host must be set as the Redis server hostname (default: localhost)
- :port must be set as the Redis server port (default: 6379)
- :base must be set as the Redis base number (default: 1)
- :auth should be set if Redis need an simple authentification key <mykey>

##### Prometheus configuration

Prometheus services could be configured in /etc/splash.yaml

    # vi /etc/splash.yml
    [...]
      :prometheus:
        :pushgateway: http://localhost:9091
        :url: http://localhost:9090
        :alertmanager: http://localhost:9093

    [...]

-  :pushgateway should be set as the Prometheus PushGateway url (default: http://localhost:9091 )
-  :url should be set as the Prometheus main service (default: http://localhost:9090)
-  :alertmanager should be set as the Prometheus Alertmanager service (default: http://localhost:9093)

### The Splash daemon

#### Introduction

We're going to discover the Big part of Splash the Daemon, usefull to :

- orchestration
- scheduling
- Log monitoring (without CRON scheduling)
- Process monitoring (without CRON scheduling)
- Transfers scheduling (TODO)
- host2host sequences execution (optionnal )


#### Prerequisite

Splash Daemon requiere Rabbitmq Configured and launched
if you try to run Splash with Rabbitmq, it will be failed :

    # sudo splash dae start
    ⛔ Splash Service dependence missing : RabbitMQ Transport not available.

*WARNING : if RabbitMQ service shutdown, Splash will shutdown also !*

You cloud configure RabbitMQ in the /etc/splash.yml :

    [...]
    :transports:
      :active: :rabbitmq
      :rabbitmq:
        :vhost: "/"
        :port: 5672
        :host: localhost
    [...]

*RabbitMQ, is the only transport service usable actually in Splash*

Where :
* vhost: is the RabbitMQ vhost used to store Splash Queues
* port : the TCP RabbitMQ port (default : 5672)
* Host : the hostname or IP of the RabbitMQ service (default : localhost)

#### the Daemon Splash subcommand

run this command :

    # splash daemon
    Commands:
      splash daemon getjobs         # send a get_jobs verb to HOSTNAME daemon over transport (need an active tranport), Typicallly Ra...
      splash daemon getjobs         # send a reset verb to HOSTNAME daemon over transport (need an active tranport), Typicallly RabbitMQ
      splash daemon help [COMMAND]  # Describe subcommands or one specific subcommand
      splash daemon ping HOSTNAME   # send a ping to HOSTNAME daemon over transport (need an active tranport), Typicallly RabbitMQ
      splash daemon purge           # Purge Transport Input queue of Daemon
      splash daemon start           # Starting Splash Daemon
      splash daemon status          # Splash Daemon status
      splash daemon stop            # Stopping Splash Daemon

#### Controlling the daemon

##### Running Daemon

    # sudo splash dae start
    ℹ Queue : splash.live.input purged
    👍 Splash Daemon Started, with PID : 16904
    💪 Splash Daemon successfully loaded.

Start command support multiples options, you cloud see it by typing :

    # sudo splash dae help start
    Usage:
      splash daemon start

      Options:
        -F, [--foreground], [--no-foreground]  
            [--purge], [--no-purge]            
                                         # Default: true
            [--scheduling], [--no-scheduling]  
                                         # Default: true

      Description:
        Starting Splash Daemon

        With --foreground, run Splash in foreground

        With --no-scheduling, inhibit commands scheduling

        With --no-purge, inhibit purge Input Queue for Splash Daemon


##### Status Daemon

if daemon is stopped :

    # sudo splash dae status
    🔹 Splash Process not found
    🔹 and PID file don't exist
    💪 Status OK


If daemon is running :

    # splash dae status
    🔹 Splash Process is running with PID 974
    🔹 and PID file exist with PID 974
    💪 Status OK


##### Stopping Daemon

    # sudo splash dae stop
    💪 Splash stopped succesfully


#### Configuring the daemon

the configuration of the daemon could be done in the /etc/splash.yml
    [...]
    :daemon:
      :logmon_scheduling:
        :every: 20s
      :metrics_scheduling:
        :every: 15s
      :procmon_scheduling:
        :every: 20s
      :process_name: 'Splash : daemon.'
      :files:
        :stdout_trace: stdout.txt
        :stderr_trace: stderr.txt
        :pid_file: splash.pid
[...]

Where :

* logmon_scheduling : (Hash) a scheduling for Log monitoring, (default: every 20s) it support :
  * :every: "<timing>" ex: "1s", "3m", "2h"
  * :at: "<date/time>" ex: "2030/12/12 23:30:00"
  * :cron: * * * * * a cron format


* metrics_scheduling : (Hash) a scheduling for internals metrics for  daemon, (default: every 20s), scheduled as logmon_scheduling

* procmon_scheduling : (Hash) a scheduling for Process monitoring, (default: every 20s), scheduled as logmon_scheduling

[Rufus Scheduler Doc](https://github.com/jmettraux/rufus-scheduler)


#### Daemon metrics


### Ecosystem

#### Execution report Template adaptions

TODO

#### Ubuntu Ansible playbook

TODO

#### Systemd integration fo daemon

TODO

#### CRON usage with or without rvmsudo

TODO

#### Default values for configuration

 defined in the lib/splash/constants.rb



     # Current splash version
     VERSION = "0.8.3"
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



#### Splash CLI return code significations


    EXIT_MAP= {

       # context execution
       :not_root => {:message => "This operation need to be run as root (use sudo or rvmsudo)", :code => 10},
       :options_incompatibility => {:message => "Options incompatibility", :code => 40},
       :service_dependence_missing => {:message => "Splash Service dependence missing", :code => 60},

       # config
       :specific_config_required => {:message => "Specific configuration required", :code => 30},
       :splash_setup_error => {:message => "Splash Setup terminated unsuccessfully", :code => 25},
       :splash_setup_success => {:message => "Splash Setup terminated successfully", :code => 0},
       :splash_sanitycheck_error => {:message => "Splash Sanitycheck terminated unsuccessfully", :code => 20},
       :splash_sanitycheck_success => {:message => "Splash Sanitycheck terminated successfully", :code => 0},
       :configuration_error => {:message => "Splash Configuration Error", :code => 50},


       # global
       :quiet_exit => {:code => 0},
       :error_exit => {:code => 99, :message => "Operation failure"},

       # events
       :interrupt => {:message => "Splash user operation interrupted", :code => 33},

       # request
       :not_found => {:message => "Object not found", :code => 44},
       :already_exist => {:message => "Object already exist", :code => 48},

       # daemon
       :status_ok => {:message => "Status OK", :code => 0},
       :status_ko => {:message => "Status KO", :code => 31}

    }


### The Splash WebAdmin

#### Controlling WebAdmin

#### Starting
#### Stopping
#### Status


#### Accessing WebAdmin


### the SPlash API


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Context

*Massively made during COVID-19 containment : #StayAtHomeSoftware*
