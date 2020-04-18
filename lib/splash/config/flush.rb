module Splash
  module ConfigUtilities
    include Splash::Constants


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
