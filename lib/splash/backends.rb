Dir[File.dirname(__FILE__) + '/backends/*.rb'].each {|file| require file  }

module Splash
  module Backends
    include Splash::Config
    def get_backend(store)
      aclass = "Splash::Backends::#{get_config[:backends][:stores][store][:type].to_s.capitalize}"
      return Kernel.const_get(aclass)::new(store)
    end

  end
end
