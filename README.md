# Splash

SPLASH is *Supervision with Prometheus of Logs and Asynchronous tasks for Services or Hosts*


Prometheus Logs and Batchs supervision over PushGateway


## Preconfiguration

You need a Prometheus PushGateway operational, if the service not run on localhost:9091,
See Configuration chapter to precise it in the configuration

## Installation


Install with gem command :

    $ gem install splash


## Configuration

As root or with rvmsudo, if you use RVM.

    # splash config setup              
    Splash -> setup :
    * Installing Configuration file : /etc/splash.yml : [OK]
    * Installing template file : /etc/splash_execution_report.tpl : [OK]
    * Creating/Checking pid file path : /var/lib/splash : [OK]
    * Creating/Checking trace file path : /var/lib/splash : [OK]
    Splash config successfully done.

*WARNING : if you have already configured Splash, running this command without --prevent-configs flag, RESET the Splash Configuration.*


As root, edit /etc/splash.conf and adapt Prometheus Pushgateway Configuration :

    # vi /etc/splash.yml
    [..]
      :prometheus:
        :pushgateway:
          :host: <SERVER>
          :port: <PORT>
    [..]

With :

- SERVER : IP or fqdn of the Gateway.
- PORT : the specific TCP port of the Gateway.


### Sanitycheck

As root or with rvmsudo, if you use RVM.

    # splash conf san
    Splash -> sanitycheck :
    * Config file : /etc/splash.yml : [OK]
    * PID Path : /tmp : [OK]
    * trace Path : /tmp/splash : [OK]
    * Prometheus PushGateway Service running : [OK]
    Sanitycheck finished with no errors

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
    Splash version : 0.0.3, Author : Romain GEORGES <gems@ultragreen.net>
    Ultragreen (c) 2020 BSD-2-Clause


## Usage

### Logs monitoring

#### Edit your configuration


In the /etc/splash.yml, you need to adapt default config to monitor your logs.

    # vi /etc/splash.yml
    [..]
    ### configuration of monitored logs
      :logs:
        - :log: /a/log/path.log
          :pattern: <regexp pattern>
        - :log: /an/other/log/path.log
          :pattern: <regexp pattern
        - <etc...>
    [..]

Config for log is a YAML list of Hash, with keys :

- :log : a log absolut paths
- :pattern : a regular expression splash need to detect


#### Prerequisite

To ensure you have the default configuration values run as root :

    # splash conf set

*INFO* : comamnds must be reduce with the Thor completion facilities

To see all monitoring commands with Splash, run :

    # splash logs

or

    # slash logs help
    Commands:
      splash logs analyse         # analyze logs in config
      splash logs help [COMMAND]  # Describe subcommands or one specific subcommand
      splash logs list            # Show configured logs monitoring
      splash logs monitor         # monitor logs in config
      splash logs show LOG        # show configured log monitoring for LOG

*Typicallly, the way work with all Splash commands or subcommands*



#### Run a first test

Verify /tmp/test and /tmp/test2 not existence

    # rm /tmp/test /tmp/test2

Verify configured logs :

    # splash logs list
    Splash configured log monitoring :
     *  log monitor : /tmp/test
     *  log monitor : /tmp/test2

You could run list commands with --detail option , verify it with :

    # splash command subcommand help

like :

    # splash logs list --detail
    Splash configured log monitoring :
     *  log monitor : /tmp/test
      ->   pattern : /ERROR/
     *  log monitor : /tmp/test2
      ->   pattern : /ERROR/

You cloud view a specific logs record detail with

    # splash logs show /tmp/test2  
    Splash log monitor : /tmp/test2
      ->   pattern : /ERROR/

Run a first analyse, you would see :

    # splash logs analyse
    SPlash Configured logs status :
      * Log : /tmp/test : [KO]
        - Detected pattern : ERROR
        - detailled Status : missing
      * Log : /tmp/test2 : [KO]
        - Detected pattern : ERROR
        - detailled Status : missing
    Global Status : [KO]

Create empty Files, or without ERROR string in.

    # echo 'foo' > /tmp/test
    # touch /tmp/test2

Re-run analyse :

    # splash log an
    SPlash Configured logs status :
      * Log : /tmp/test : [OK]
        - Detected pattern : ERROR
        - detailled Status : clean
          nb lines = 1
      * Log : /tmp/test2 : [OK]
        - Detected pattern : ERROR
        - detailled Status : clean
          nb lines = 0
    Global Status : [OK]

It's alright, log monitoring work fine.

#### Send metrics to Prometheus gateway

Splash is made to run a specific daemon to do this job, but you could do one time, with :

    # splash logs monitor
    Sending metrics to Prometheus Pushgateway
      * Sending metrics for /tmp/test
      * Sending metrics for /tmp/test2
    Sending done.

if Prometheus Gateway is not running or misconfigured, you could see :

    Prometheus PushGateway Service IS NOT running
    Exit without notification.

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

![prom PG logs](assets/images/prom_pg_logs.png)

![prom PG details logs](assets/images/detail_prom_splash.png)


### Commands Orchestration, running and monitoring

#### List of commands

To see all the commands in the 'commands' submenu :

    $ splash commands help

    $ splash commands                           
    Commands:
      splash commands help [COMMAND]   # Describe subcommands or one specific subcommand
      splash commands lastrun COMMAND  # Show last running result for specific configured command COMMAND
      splash commands list             # Show configured commands
      splash commands run NAME         # run for command/sequence or ack result
      splash commands show COMMAND     # Show specific configured command COMMAND
      splash commands treeview         # Show commands sequence tree

#### test with default configuration

Commands or Commands Sequences must be defined in the main configuration file '/etc/splash.yml'

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

* :on_failure: the name of an other defined command, to, execute if exit_code > 0
* :on_success: the name of an other defined command, to, execute if exit_code = 0
* :schedule:  (hash) a scheduling for daemon, after in this documentation, it support :
  * :every: "<timing>" ex: "1s", "3m", "2h"
  * :at: "<date/time>" ex: "2030/12/12 23:30:00"
  * :cron: * * * * * a cron format

[Rufus Scheduler Doc](https://github.com/jmettraux/rufus-scheduler)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
