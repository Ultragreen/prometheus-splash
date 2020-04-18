# coding: utf-8
module Splash
  module Backends
    class File
      include Splash::Config
      include Splash::Exiter
      include Splash::Helpers
      include Splash::Loggers

      def initialize(store)
        @config = get_config[:backends][:stores][store]
        @path = @config[:path]
        ensure_backend
      end

      def list(pattern='*')
        pattern = suffix_trace(pattern)
        return Dir.glob("#{@path}/#{pattern}").map{|item| ::File.basename(item,".trace") }
      end

      def get(options)
        return ::File.readlines("#{@path}/#{suffix_trace(options[:key])}").join
      end

      def put(options)
        ::File.open("#{@path}/#{suffix_trace(options[:key])}", 'w') { |file|
          file.write options[:value]
        }
      end

      def del(options)
        ::File.unlink("#{@path}/#{suffix_trace(options[:key])}") if File.exist?("#{@path}/#{suffix_trace(options[:key])}")
      end

      def exist?(options)
        return ::File.exist?("#{@path}/#{suffix_trace(options[:key])}")
      end

      def flush
        Dir.glob("#{@path}/*.trace").each { |file| ::File.delete(file)}
      end

      private
      def suffix_trace(astring)
        return "#{astring}.trace"
      end

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
