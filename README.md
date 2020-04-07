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

### Testing Logs analyse with default configuration values


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

metric_count = Prometheus::Client::Gauge.new(:logerrors, docstring: 'SPLASH metric log error', labels: [:log ])
@metric_missing = Prometheus::Client::Gauge.new(:logmissing, docstring: 'SPLASH metric log missing', labels: [:log ])
@metric_lines = Prometheus::Client::Gauge.new(:loglines, docstring: 'SPLASH metric log lines numbers', labels: [:log ])

- *logerrors* , Prometheus Gauge : with label: <the logname> and job: 'Splash', decription : SPLASH metric log error'
  ->  <nb match> the number of pattern matching for the log
- *logmissing*, Prometheus Gauge : with label: <the logname> and job: 'Splash', decription : SPLASH metric log missing'
  -> 0 if log exist, 1 if log missing
- *loglines*, Prometheus Gauge : with label: <the logname> and job: 'Splash', decription : SPLASH metric log line numbers'
  -> 0 if log missing, <nb lines in the log> the number of lines in the logs

#### See it in Prometheus PushGateway

![prom PG logs](assets/images/prom_pg_logs.png)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
