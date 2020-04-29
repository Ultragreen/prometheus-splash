# coding: utf-8

# Base Splash module
module Splash

  # module for Configuration utilities
  module ConfigUtilities
    include Splash::Constants

    # clean backend action method
    # @param [Hash] options
    # @option options [Symbol] :name the name of the backend (:redis, :file)
    # @return [Hash] An Exiter case hash (:quiet_exit or :configuration_error)
    def flush_backend(options ={})
      config = get_config
      self.extend Splash::Backends
      self.extend Splash::Loggers
      log = get_logger
      log.info "Splash backend flushing"
      name  = (options[:name])? options[:name] : :execution_trace
      backend = get_backend name
      if backend.flush then
        return { :case => :quiet_exit, :more => "Splash backend #{name.to_s} flushed" }
      else
        return { :case => :configuration_error, :more => "Splash backend #{name.to_s} can't be flushed" }
      end
    end

  end
end
