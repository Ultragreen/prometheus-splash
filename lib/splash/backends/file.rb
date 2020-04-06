module Splash
  module Backends
    class File
      include Splash::Config
      def initialize(store)
        @config = get_config[:backends][:stores][store]
        @path = @config[:path]
      end

      def list(pattern='*')
         return Dir.glob(pattern)
      end

      def get(options)
        return ::File.readlines("#{@path}/#{options[:key]}").join
      end

      def put(options)
        ::File.open("#{@path}/#{options[:key]}", 'w') { |file|
          file.write options[:value]
        }
      end

      def del(options)
        ::File.unlink("#{@path}/#{options[:key]}") if File.exist?("#{@path}/#{options[:key]}")
      end

      def exist?(options)
        return ::File.exist?("#{@path}/#{options[:key]}")
      end

    end
  end

end
