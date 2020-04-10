# coding: utf-8
module Splash
  module Backends
    class File
      include Splash::Config
      def initialize(store)
        @config = get_config[:backends][:stores][store]
        @path = @config[:path]
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

      private
      def suffix_trace(astring)
        return "#{astring}.trace"
      end

    end
  end

end
