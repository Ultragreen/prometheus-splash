module Splash
  module Exiter
    EXIT_MAP= {
       :not_root => {:message => "Command wrapping need to be run as root", :code => 60}
    }

    def splash_exit(options = {:status => :success})
      if options[:success] then
      else
        $stderr.puts EXIT_MAP[:case][:message]
        exit EXIT_MAP[:case][:code]
      end
    end

  end
end
