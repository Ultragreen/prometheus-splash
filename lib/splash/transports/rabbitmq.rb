# coding: utf-8

# base Splash module
module Splash

  # Splash Transports namespace
  module Transports

    # RabbitMQ Transport
    module Rabbitmq

      # Subscriber Mode RabbitMQ Client
      class Subscriber
        include Splash::Config
        extend Forwardable

        def_delegators :@queue, :subscribe

        # Constructor Forward subscribe method and initialize a Bunny Client atribute @queue
        # @param [Hash] options
        # @option options [String] :queue the name of the subscribed queue
        def initialize(options = {})
          @config = get_config.transports

          host = @config[:rabbitmq][:host]
          port = @config[:rabbitmq][:port]
          vhost = (@config[:rabbitmq][:vhost])? @config[:rabbitmq][:vhost] : '/'
          passwd = (@config[:rabbitmq][:passwd])? @config[:rabbitmq][:passwd] : 'guest'
          user = (@config[:rabbitmq][:user])? @config[:rabbitmq][:user] : 'guest'
          conf  = { :host => host, :vhost => vhost, :user => user, :password => passwd, :port => port.to_i}

          begin
            @connection = Bunny.new conf
            @connection.start
            @channel = @connection.create_channel
            @queue    = @channel.queue options[:queue]
          rescue Bunny::Exception
            return  { :case => :service_dependence_missing, :more => "RabbitMQ Transport not available." }
          end
        end


      end

      # publish / get Mode RabbitMQ Client
      class Client
        include Splash::Config
        include Splash::Transports
        include Splash::Loggers

        # Constructor initialize a Bunny Client
        def initialize
          @config = get_config.transports
          host = @config[:rabbitmq][:host]
          port = @config[:rabbitmq][:port]
          vhost = (@config[:rabbitmq][:vhost])? @config[:rabbitmq][:vhost] : '/'
          passwd = (@config[:rabbitmq][:passwd])? @config[:rabbitmq][:passwd] : 'guest'
          user = (@config[:rabbitmq][:user])? @config[:rabbitmq][:user] : 'guest'
          conf  = { :host => host, :vhost => vhost, :user => user, :password => passwd, :port => port.to_i}

          begin
            @connection = Bunny.new conf
            @connection.start
            @channel = @connection.create_channel
          rescue Bunny::Exception
            splash_exit  case: :service_dependence_missing, more: "RabbitMQ Transport not available."
          end
        end

        # purge a queue
        # @param [Hash] options
        # @option options [String] :queue the name of the queue to purge
        def purge(options)
          @channel.queue(options[:queue]).purge
        end

        # publish to a queue
        # @param [Hash] options
        # @option options [String] :queue the name of the queue to purge
        # @option options [String] :message the message to send
        def publish(options ={})
          return @channel.default_exchange.publish(options[:message], :routing_key => options[:queue])
        end

        # ack a specific message for manual ack with a delivery tag to a queue
        # @param [String] ack
        # @return [Boolean]
        def ack(ack)
          return @channel.acknowledge(ack, false)
        end


        # send an execution order message (verb+payload) via RabbitMQ to an slash input queue
        # @param [Hash] order
        # @return [Void] unserialized Void object from YAML
        def execute(order)
          queue = order[:return_to]
          lock = Mutex.new
          res = nil
          condition = ConditionVariable.new
          get_default_subscriber(queue: queue).subscribe do |delivery_info, properties, payload|
            res = YAML::load(payload)
            lock.synchronize { condition.signal }
          end
          get_logger.send "Verb : #{order[:verb].to_s} to queue : #{order[:queue]}."
          get_default_client.publish queue: order[:queue], message: order.to_yaml
          lock.synchronize { condition.wait(lock) }
          return res
        end

        # Get a message from a RabbitMQ queue
        # @param [Hash] options
        # @option options [String] :queue the name of the queue to query
        # @option options [String] :manual_ack flag to inhibit ack
        # @return [Hash] Payload + ack tag if :manual_ack
        def get(options ={})
          queue = @channel.queue(options[:queue])
          opt = {}; opt[:manual_ack] = (options[:manual_ack])? true : false
          delivery_info, properties, payload = queue.pop
          res = {:message => payload}
          res[:ack] = delivery_info.delivery_tag if options[:manual_ack]
          return res
        end

        # close the RabbitMQ connection
        def close
          @connection.close
        end

      end
    end
  end
end
