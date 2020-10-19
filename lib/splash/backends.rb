# coding: utf-8
Dir[File.dirname(__FILE__) + '/backends/*.rb'].each {|file| require file  }

# base Splash Module
module Splash

  # generic backends module
  module Backends
    include Splash::Config
    include Splash::Constants

    # factory for backend
    # @param [Symbol] store the name of the store actually in [:execution_trace]
    # @return [Splash::Backends::<Type>|Hash] with type in [:redis,:file] or Exiter case :configuration_error 
    def get_backend(store)
      splash_exit case: :configuration_error, more: "backend definition failure" if get_config[:backends][:stores][store].nil?
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
