require "redis"

module Splash
  module Backends
    class Redis
      include Splash::Config
      def initialize(store)
        @config = get_config[:backends][:stores][store]
        @store = ::Redis.new :host => @config[:host], :port => @config[:port], :db => @config[:base].to_i
        @redis_cli_cmd = `which redis-cli`
        @store.auth(@config[:auth]) if @config[:auth]
      end

      def list(pattern='*')
         return @store.keys pattern
      end

      def get(options)
        return @store.get(options[:key])
      end

      def put(options)
        @store.set options[:key], options[:value]
      end

      def del(options)
        @store.del options[:key]
      end

      def flush
        `#{@redis_cli_cmd} -n 3 flushdb`
        # @@store.flushdb
      end

      def exist?(options)
        return ( not @store.get(options[:key]).nil?)
      end

    end
  end

end
