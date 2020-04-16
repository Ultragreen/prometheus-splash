# SPLASH CHANGELOG


## V 0.3.0 2020/04/11

* Begining of Changelog tracking

## V 0.4.0 2020/04/14

### DOC :

* adding \n for LONGDESC Thor #14
* Doc for command name format in YAML #2

### CHANGE :

* RabbitMQ Credentials and vhosts support #16
* backend hardening #18
* remote show with --hostname #12


### FEATURE :

* CLI colors and logger CLI /dual #8
* Log for splash daemon #6
* Schedule command via daemon execute and --hostname #11

## V 0.4.1 2020/04/15

### FIX :

* Unix rights on trace,stores,pid path to 644 => 755 #19

## V0.4.2 2020/04/15

### FIX :

* REOPEN : Unix rights on trace,stores,pid path to 644 => 755 #19
* ruby 2.5 error with w-deprecated on sheebang, removing #20

## V0.4.3 2020/04/15

### FIX :

* private method for ruby 2.5 (self) #21
* treeview partial display because of lake of recursion #22