# coding: utf-8
require 'fileutils'
# coding: utf-8
module Splash
  module Helpers

    # method for daemonize blocks
    # @param [Hash] _options the list of options, keys are symbols
    # @option  _options [String] :description the description of the process, use for $0
    # @option  _options [String] :pid_file the pid filenam
    # @yield a process definion or block given
    # @example usage inline
    #    class Test
    #      include Splash::Helpers::Application
    #      private :daemonize
    #      def initialize
    #        @loop = Proc::new do
    #          loop do
    #            sleep 1
    #          end
    #        end
    #      end
    #
    #      def run
    #        daemonize({:description => "A loop daemon", :pid_file => '/tmp/pid.file'}, &@loop)
    #      end
    #     end
    #
    # @example usage block
    #    class Test
    #      include Splash::Helpers::Application
    #      include Dorsal::Privates
    #      private :daemonize
    #      def initialize
    #      end
    #
    #      def run
    #        daemonize :description => "A loop daemon", :pid_file => '/tmp/pid.file' do
    #          loop do
    #            sleep 1
    #          end
    #        end
    #      end
    #     end
    # @return [Fixnum] pid the pid of the forked processus
    def daemonize(_options)
      return yield if options[:debug]
      trap("SIGINT"){ exit! 0 }
      trap("SIGTERM"){ exit! 0 }
      trap("SIGHUP"){ exit! 0 }

      fork do
        Process.daemon
        $stdout.reopen("/tmp/out.txt", "w")
        $stderr.reopen("/tmp/err.txt", "w")
        File.open(options[:pid_file],"w"){|f| f.puts Process.pid } if options[:pid_file]
        $0 = options[:description]

        yield

      end
      return true
    end

    # @!group facilités sur le système de fichier

    # facilité de copy de fichier
    # @param [Hash] options
    # @option options [String] :source le chemin source du fichier
    # @option options [String] :target le chemin cible du fichier
    def copy_file(options = {})
      FileUtils::copy options[:source], options[:target] unless File::exist? options[:target]
    end

    # facilité de création de répertoire
    # @param [Hash] options
    # @option options [String] :path le répertoire à créer (relatif ou absolut)
    def make_folder(options = {})
      FileUtils::mkdir_p options[:path] unless File::exist? options[:path]
    end

    # facilité de liaison symbolique  de fichier
    # @param [Hash] options
    # @option options [String] :source le chemin source du fichier
    # @option options [String] :link le chemin du lien symbolique
    def make_link(options = {})
      FileUtils::rm options[:link] if (File::symlink? options[:link] and not File::exist? options[:link])
      FileUtils::ln_s options[:source], options[:link] unless File::exist? options[:link]
    end
    # @!endgroup


    #@!group  Vérifiers de l'application

    # verifier d'existence d'un repertoire
    # @return [Bool] vrai ou faux
    # @param [Hash] options
    # @option options [String] :path le répertoire à créer (relatif ou absolut)
    def verify_folder(options ={})
      return File.directory?(options[:path])
    end

    # verifier d'existence d'un lien
    # @return [Bool] vrai ou faux
    # @param [Hash] options
    # @option options [String] :name path du lien
    def verify_link(options ={})
      return File.file?(options[:name])
    end

    # verifier d'existence d'un fichier
    # @return [Bool] vrai ou faux
    # @param [Hash] options
    # @option options [String] :name path du fichier
    def verify_file(options ={})
      return File.file?(options[:name])
    end

    # verifier de l'ecoute d'un service sur un host et port donné en TCP
    # @return [Bool] vrai ou faux
    # @param [Hash] options
    # @option options [String] :host le nom d'hote
    # @option options [String] :port le port TCP
    def verify_service(options ={})
      begin
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new(options[:host], options[:port])
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
        return false
      end
    end
    #!@endgroup



  end
end
