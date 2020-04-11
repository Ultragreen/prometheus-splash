# coding: utf-8
Dir[File.dirname(__FILE__) + '/backends/*.rb'].each {|file| require file  }

module Splash
  module Backends
    include Splash::Config
    include Splash::Constants

    def get_backend(store)
      backend = get_config[:backends][:stores][store][:type].to_s
      aclass = "Splash::Backends::#{backend.capitalize}"
      begin
        return Kernel.const_get(aclass)::new(store)
      rescue
        splash_exit case: :configuration_error, more: "Backend specified for store #{store} inexistant : #{backend}"
      end
    end

  end
end
