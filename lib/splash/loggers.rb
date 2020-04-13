# coding: utf-8

Dir[File.dirname(__FILE__) + '/loggers/*.rb'].each {|file| require file  }

module Splash
  module Loggers

    @@logger=nil

    clas

    def get_logger(options = {})
      logger = (get_config.loggers[:list].include? options[:logger])? options[:logger] : get_config.loggers[:default].to_s
      aclass = "Splash::Loggers::#{logger.capitalize}"
      begin
        return @@logger = Kernel.const_get(aclass)::new(store) if options[:force]
        return @@logger ||= Kernel.const_get(aclass)::new(store)
      rescue
        splash_exit case: :configuration_error, more: "Logger specified inexistant : #{logger}"
      end
    end


    def change_logger(options = {})
      options[:force] = true
      get_logger(options)
    end


  end
end
