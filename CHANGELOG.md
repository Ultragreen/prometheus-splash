# SPLASH CHANGELOG


## V 0.3.0 2020/04/11

* Begining of Changelog tracking

## V 0.4.0 2020/04/14

### DOC :

* adding \n for LONGDESC Thor #14
* Doc for command name format in YAML #2

### CHANGES :

* RabbitMQ Credentials and vhosts support #16
* backend hardening #18
* remote show with --hostname #12


### FEATURES :

* CLI colors and logger CLI /dual #8
* Log for splash daemon #6
* Schedule command via daemon execute and --hostname #11

## V 0.4.1 2020/04/15

### FIX :

* Unix rights on trace,stores,pid path to 644 => 755 #19

## V 0.4.2 2020/04/15

### FIX :

* REOPEN : Unix rights on trace,stores,pid path to 644 => 755 #19
* ruby 2.5 error with w-deprecated on sheebang, removing #20

## V 0.4.3 2020/04/15

### FIX :

* private method for ruby 2.5 (self) #21
* treeview partial display because of lake of recursion #22

## V 0.4.4 2020/04/17

### FIX :

* Redis auth #33
* RabbitMQ param url not hash in initialize #29
* UTF8 detection without TERM ENV var #30

### DOC :

* prepare Vagrantfile and Ansible playbook


## V 0.4.5 2020/04/17

### FIX :

* RabbitMQ Exception catching + refacto connection #31  


## V 0.5.0 2020/04/17

### FIX

* auto setup root check without /etc/splash.yml #34
* empty hostname with --hostname #27
* foreground execution control #24
* root required for file backend with command last and get #36

### FEATURES

* command treeview with --hostname #28
* log horodating with PID #35
* quiet mode + no-colors and no-emoji #5
* correlation id in log for daemon #15
* systemd Splashd service installation #32


## V 0.5.1 2020/04/17

### CHANGES

* short Alias for commands without --no-[xxxx] #38

### FEATURES

* flush backend arg in config #41
* adding global --debug flag

### DOC

* default value of mon scheduling 20s => 1m in ansible splash.yml


### FIX

* Ansible Splash role handler error
* Ansible Splash role logrotate copytruncate for splash logs
