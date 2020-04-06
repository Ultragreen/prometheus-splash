require 'bunny'
module Splash
  module Transports
    module RabbitMQ

      class Subscriber
        def initialize

        end
      end


      class Client
        def initialize
          @connection = Bunny.new
          @connection.start
          @channel = @connection.create_channel
        end


        def publish(options ={})
          return @channel.default_exchange.publish(options[:message], :routing_key => options[:queue])
        end

        def ack
          return @channel.acknowledge(delivery_info.delivery_tag, false)
        end


        def get(options ={})
          queue = @channel.queue(options[:queue])
          delivery_info, properties, payload = queue.pop
          res = {:message => payload}
          res[:ack] = delivery_info.delivery_tag if options[:noack]
          return res
        end

        def close
          @connection.close
        end

      end
    end
  end
end
