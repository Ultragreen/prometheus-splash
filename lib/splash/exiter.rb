module Splash
  module Exiter
    EXIT_MAP= {
       :not_root => {:message => "This operation need to be run as root (use sudo or rvmsudo)", :code => 10},
       :command_not_configured => {:message => "Command not configured", :code => 51},
       :options_incompatibility => {:message => "Options incompatibility", :code => 40},
       :redis_back_required => {:message => "Redis backend is requiered for the action", :code => 30},
       :splash_setup_error => {:message => "Splash Setup terminated unsuccessfully", :code => 25},
       :splash_setup_success => {:message => "Splash Setup terminated successfully", :code => 0},
       :splash_sanitycheck_error => {:message => "Splash Sanitycheck terminated unsuccessfully", :code => 20},
       :splash_sanitycheck_success => {:message => "Splash Sanitycheck terminated successfully", :code => 0},
       :quiet_exit => {:code => 0},
       :service_dependence_missing => {:message => "Splash Service dependence missing", :code => 60},
       :interrupt => {:message => "Splash user operation interrupted", :code => 33},
       :configuration_error => {:message => "Splash Configuration Error", :code => 50},
       :not_found => {:message => "Object not found", :code => 404},

    }

    def splash_exit(options = {:status => :success})
      mess = EXIT_MAP[:case][:message] if EXIT_MAP[:case][:message]
      mess << " : #{options[:more] if options[:more]}""
      if  EXIT_MAP[:case][:code] = 0 then
        puts mess if mess
        exit 0
      else
        $stderr.puts mess
        exit EXIT_MAP[:case][:code]
      end
    end



  end
end
