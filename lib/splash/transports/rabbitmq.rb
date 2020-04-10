# coding: utf-8
module Splash
  module Transports
    module Rabbitmq

      class Subscriber
        include Splash::Config
        extend Forwardable

        def_delegators :@queue, :subscribe

        def initialize(options = {})
          @config = get_config.transports
          @connection = Bunny.new url: @config[:rabbitmq][:url]
          @connection.start
          @channel = @connection.create_channel
          @queue    = @channel.queue options[:queue]

        end


      end


      class Client
        include Splash::Config
        include Splash::Transports

        def initialize
          @config = get_config.transports
          @connection = Bunny.new url: @config[:rabbitmq][:url]
          @connection.start
          @channel = @connection.create_channel
        end


        def publish(options ={})
          return @channel.default_exchange.publish(options[:message], :routing_key => options[:queue])
        end

        def ack(ack)
          return @channel.acknowledge(ack, false)
        end

        def execute(order)
          queue = order[:return_to]
          lock = Mutex.new
          res = nil
          condition = ConditionVariable.new
          get_default_subscriber(queue: queue).subscribe(timeout: 5) do |delivery_info, properties, payload|
            res = YAML::load(payload)
            lock.synchronize { condition.signal }
          end
          get_default_client.publish queue: order[:queue], message: order.to_yaml
          lock.synchronize { condition.wait(lock) }
          return res
        end

        def get(options ={})
          queue = @channel.queue(options[:queue])
          opt = {}; opt[:manual_ack] = (options[:manual_ack])? true : false
          delivery_info, properties, payload = queue.pop
          res = {:message => payload}
          res[:ack] = delivery_info.delivery_tag if options[:manual_ack]
          return res
        end

        def close
          @connection.close
        end

      end
    end
  end
end
