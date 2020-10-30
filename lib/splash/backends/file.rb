# coding: utf-8

# base Splash Module
module Splash
  # generic backends module
  module Backends

    # File backend definition
    class File
      include Splash::Config
      include Splash::Exiter
      include Splash::Helpers
      include Splash::Loggers

      # Constructor
      # @param [Symbol] store name in [:execution_trace] actually (see config and constants )
      # @return [Splash::Backends::File] a File backend
      def initialize(store)
        @config = get_config[:backends][:stores][store]
        @path = @config[:path]
        ensure_backend
      end

      # return the list of find records in backend for a specific pattern
      # @param [String] pattern shell regexp
      # @return [Array] list of record
      def list(pattern='*')
        pattern = suffix_trace(pattern)
        return Dir.glob("#{@path}/#{pattern}").map{|item| ::File.basename(item,".trace") }
      end


      # return value of queried record
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [String] content value of record
      def get(options)
        return ::File.readlines("#{@path}/#{suffix_trace(options[:key])}").join
      end

      # defined and store value for specified key
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @option options [Symbol] :value the content value of the record
      # @return [String] content value of record
      def put(options)
        ::File.open("#{@path}/#{suffix_trace(options[:key])}", 'w') { |file|
          file.write options[:value]
        }
      end

      # delete a specific record
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [Boolean] status of the operation
      def del(options)
        ::File.unlink("#{@path}/#{suffix_trace(options[:key])}") if ::File.exist?("#{@path}/#{suffix_trace(options[:key])}")
      end

      # verifiy a specific record existance
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [Boolean] presence of the record
      def exist?(options)
        return ::File.exist?("#{@path}/#{suffix_trace(options[:key])}")
      end

      # flush all records in backend
      def flush
        Dir.glob("#{@path}/*.trace").each { |file| ::File.delete(file)}
      end

      private

      # File backend specific method for suffixing record name with .trace for filename
      # @param [String] astring
      # @return [String] suffixed string
      def suffix_trace(astring)
        return "#{astring}.trace"
      end

      # File backend specific method to test backend, correcting if requiered, spool path checking
      # @return [True|Hash] Exiter case :configuration_error if failing to correct backend
      def ensure_backend
        unless verify_folder(name: @config[:path], mode: "644", owner: get_config.user_root, group: get_config.group_root).empty? then
          get_logger.warn "File Backend folder : #{@config[:path]} is missing"
          if make_folder path: @config[:path], mode: "644", owner: get_config.user_root, group: get_config.group_root then
            get_logger.ok "File Backend folder : #{@config[:path]} created"
          else
            splash_exit case: :configuration_error, more: "File backend creation error"
          end
        end
      end

    end
  end

end
