# coding: utf-8
Dir[File.dirname(__FILE__) + '/transports/*.rb'].each {|file| require file  }

module Splash
  module Transports
    include Splash::Config

    def get_default_subscriber(queue)
      aclass = "Splash::Transports::#{get_config[:transports][:active].to_s.capitalize}::Subscriber"
      return Kernel.const_get(aclass)::new(queue)
    end

    def get_default_client
      aclass = "Splash::Transports::#{get_config[:transports][:active].to_s.capitalize}::Client"
      return Kernel.const_get(aclass)::new
    end

  end
end
