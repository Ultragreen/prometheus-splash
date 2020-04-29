# coding: utf-8

# base Splash module
module Splash

  # Splash Transports namespace
  module Transports
    include Splash::Config


    # factory for Splash::Transports::Rabbitmq::Subscriber
    # @param [Hash] options
    # @return [Splash::Transports::Rabbitmq::Subscriber|Hash] Subscriber or Exiter case :configuration_error
    def get_default_subscriber(options)
      config = get_config.transports
      transport = config[:active]
      host = config[transport][:host]
      port = config[transport][:port]
      unless verify_service host: host, port: port then
        return  { :case => :service_dependence_missing, :more => "RabbitMQ Transport not available." }
       end
      aclass = "Splash::Transports::#{transport.capitalize}::Subscriber"
      begin
        return Kernel.const_get(aclass)::new(options)
      rescue
        return { :case => :configuration_error, :more => "Transport specified for queue #{options[:queue]} configuration error : #{transport}"}
      end
    end

    # factory for Splash::Transports::Rabbitmq::Client
    # @return [Splash::Transports::Rabbitmq::Client|Hash] Client or Exiter case :configuration_error
    def get_default_client
      config = get_config.transports
      transport = config[:active]
      host = config[transport][:host]
      port = config[transport][:port]
      unless verify_service host: host, port: port then
        return  { :case => :service_dependence_missing, :more => "RabbitMQ Transport not available." }
       end
      aclass = "Splash::Transports::#{transport.to_s.capitalize}::Client"
      begin
        return Kernel.const_get(aclass)::new
      rescue
        return { :case => :configuration_error, :more => "Transport configuration error : #{transport}"}
      end
    end

  end
end

Dir[File.dirname(__FILE__) + '/transports/*.rb'].each {|file| require file  }
