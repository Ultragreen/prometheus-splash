# coding: utf-8

# base Splash namespace
module Splash

  # Exiter namespace
  module Exiter
    include Splash::Loggers
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

    # exiter wrapper
    # @param [Hash] options
    # @option options [Symbol] :case an exit case
    # @option options [String] :more a complementary string to display
    def splash_exit(options = {})
      log = get_logger
      mess = ""
      mess = EXIT_MAP[options[:case]][:message] if EXIT_MAP[options[:case]].include? :message
      mess << " : " unless mess.empty? or not options[:more]
      mess << "#{options[:more]}" if options[:more]
      if  EXIT_MAP[options[:case]][:code] == 0 then
        log.success mess unless mess.empty?
        exit 0
      else
        log.fatal mess unless mess.empty?
        exit EXIT_MAP[options[:case]][:code]
      end
    end

    def splash_return(options = {})

      data = EXIT_MAP[options[:case]]
      data[:status] = (data[:code]>0)? :failure : :success
      data[:more] = options[:more] if options[:more]
      return data
    end

  end
end
