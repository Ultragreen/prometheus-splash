Dir[File.dirname(__FILE__) + '/backends/*.rb'].each {|file| require file  }

module Splash
  module Backends
    include Splash::Config
    def get_default_backend
      aclass = "Splash::backends::#{get_config[:backends][:active].to_s.capitalize}"
      return Kernel.const_get(aclass)::new
    end

  end
end
