require "redis"
require "socket"

module Splash
  module Backends
    class Redis
      include Splash::Config
      def initialize(store)
        @hostname = Socket.gethostname
        @config = get_config[:backends][:stores][store]
        @store = ::Redis.new :host => @config[:host], :port => @config[:port], :db => @config[:base].to_i
        @redis_cli_cmd = `which redis-cli`
        @store.auth(@config[:auth]) if @config[:auth]
      end

      def list(pattern='*', hostname = @hostname)
         return @store.keys("#{hostname}##{pattern}").map{|item| item = remove_hostname(item)}
      end

      def listall(pattern='*')
         return @store.keys(pattern)
      end

      def get(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        return @store.get(prefix_hostname(options[:key],hostname))
      end

      def put(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        @store.set prefix_hostname(options[:key],hostname), options[:value]
      end

      def del(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        @store.del prefix_hostname(options[:key],hostname)
      end

      def flush
        `#{@redis_cli_cmd} -n 3 flushdb`
        # @@store.flushdb
      end

      def exist?(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        return ( not @store.get(prefix_hostname(options[:key],hostname)).nil?)
      end

      private
      def prefix_hostname(key,hostname)
        return "#{hostname}##{key}"
      end


      def remove_hostname(astring)
        result = astring.split("#")
        result.shift
        return result.join("#")
      end

    end
  end

end
