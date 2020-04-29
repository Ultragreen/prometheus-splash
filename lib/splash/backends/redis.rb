# coding: utf-8

# base Splash Module
module Splash

  # generic backends module
  module Backends

    # Redis backend definition
    class Redis
      include Splash::Config

      # Constructor
      # @param [Symbol] store name in [:execution_trace] actually (see config and constants )
      # @return [Splash::Backends::Redis] a Redis backend
      def initialize(store)
        @hostname = Socket.gethostname
        @config = get_config[:backends][:stores][store]
        conf = { :host => @config[:host], :port => @config[:port], :db => @config[:base].to_i}
        conf[:password] = @config[:auth] if @config[:auth]
        @store = ::Redis.new conf
        #@redis_cli_cmd = `which redis-cli`
        @store.auth(@config[:auth]) if @config[:auth]
      end

      # return the list of find records in backend for a specific pattern
      # @param [String] hostname optionnal (default : local hostname)
      # @param [String] pattern shell regexp
      # @return [Array] list of record (for all hostname if hostname is specified)
      def list(pattern='*', hostname = @hostname)
         return @store.keys("#{hostname}##{pattern}").map{|item| item = remove_hostname(item)}
      end

      # return the list of find records in backend for a specific pattern, without hostname Checking
      # Redis Backend specific method
      # @param [String] pattern shell regexp
      # @return [Array] list of record (for all hostname if hostname is specified)
      def listall(pattern='*')
         return @store.keys(pattern)
      end

      # return value of queried record
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [String] content value of record
      def get(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        return @store.get(prefix_hostname(options[:key],hostname))
      end

      # defined and store value for specified key
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @option options [Symbol] :value the content value of the record
      # @return [String] content value of record
      def put(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        @store.set prefix_hostname(options[:key],hostname), options[:value]
      end

      # delete a specific record
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [Boolean] status of the operation
      def del(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        @store.del prefix_hostname(options[:key],hostname)
      end

      # flush all records in backend
      def flush
        #`#{@redis_cli_cmd} -n #{@config[:base]} flushdb`
        @store.flushdb
      end

      # verifiy a specific record existance
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [Boolean] presence of the record
      def exist?(options)
        hostname = (options[:hostname])? options[:hostname] : @hostname
        return ( not @store.get(prefix_hostname(options[:key],hostname)).nil?)
      end

      private

      # Redis backend specific method for prefix record name with hostname
      # @param [String] key
      # @param [String] hostname
      # @return [String] prefixed string
      def prefix_hostname(key,hostname)
        return "#{hostname}##{key}"
      end

      # Redis backend specific method for removing hostname of record
      # @param [String] astring
      # @return [String] cleaned string
      def remove_hostname(astring)
        result = astring.split("#")
        result.shift
        return result.join("#")
      end

    end
  end

end
