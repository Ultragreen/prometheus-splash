# coding: utf-8
require 'fileutils'
require 'etc'

# coding: utf-8
module Splash
  module Helpers

    def is_root?
      case (Process.uid)
      when 0
        return true
      else
        return false
      end
    end

    def run_as_root(method)
      unless is_root?
        $stderr.puts "You need to be root to execute this subcommands : #{method.to_s}"
        $stderr.puts "Please execute with sudo, or rvmsudo."
        exit 10
      else
        self.send method
      end
    end

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
    def daemonize(options)
      #Process.euid = 0
      #Process.egid = 0
      return yield if options[:debug]
      trap("SIGINT"){ exit! 0 }
      trap("SIGTERM"){ exit! 0 }
      trap("SIGHUP"){ exit! 0 }

      fork do
        #Process.daemon
        File.open(options[:pid_file],"w"){|f| f.puts Process.pid } if options[:pid_file]
        uid = Etc.getpwnam(options[:daemon_user]).uid
        gid = Etc.getgrnam(options[:daemon_group]).gid
        Process::UID.change_privilege(uid)
      #  Process::GID.change_privilege(gid)
        $stdout.reopen(options[:stdout_trace], "w")
        $stderr.reopen(options[:stderr_trace], "w")

        #$0 = options[:description]
        Process.setproctitle options[:description]

        yield

      end
      return true
    end

    # @!group facilités sur le système de fichier

    # facilité d'installation de fichier
    # @param [Hash] options
    # @option options [String] :source le chemin source du fichier
    # @option options [String] :target le chemin cible du fichier
    def install_file(options = {})
      #begin
        FileUtils::copy options[:source], options[:target] #unless File::exist? options[:target]
        FileUtils.chmod options[:mode].to_i(8), options[:target] if options[:mode]
        FileUtils.chown options[:owner], options[:group], options[:target] if options[:owner] and options[:group]
        return true
      #rescue StandardError
        # return false
      #end
    end

    # facilité de création de répertoire
    # @param [Hash] options
    # @option options [String] :path le répertoire à créer (relatif ou absolut)
    def make_folder(options = {})
      begin
        FileUtils::mkdir_p options[:path] unless File::exist? options[:path]
        FileUtils.chmod options[:mode].to_i(8), options[:path] if options[:mode]
        FileUtils.chown options[:owner], options[:group], options[:path] if options[:owner] and options[:group]
        return true
      rescue StandardError
        return false
      end
    end

    # facilité de liaison symbolique  de fichier
    # @param [Hash] options
    # @option options [String] :source le chemin source du fichier
    # @option options [String] :link le chemin du lien symbolique
    def make_link(options = {})
      begin
        FileUtils::rm options[:link] if (File::symlink? options[:link] and not File::exist? options[:link])
        FileUtils::ln_s options[:source], options[:link] unless File::exist? options[:link]
        return true
      rescue StandardError
        return false
      end
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
      res = Array::new
      return  [:inexistant] unless File.file?(options[:name])
      stat = File.stat(options[:name])
      if options[:mode] then
        mode = "%o" % stat.mode
        res << :mode if mode[-3..-1] != options[:mode]
      end
      if options[:owner] then
        res << :owner if Etc.getpwuid(stat.uid).name != options[:owner]
      end
      if options[:group] then
        res << :group if Etc.getgrgid(stat.gid).name != options[:group]
      end
      return res
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
