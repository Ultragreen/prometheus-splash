# @option  options [String] :stdout_trace the path of the file where to redirect STDOUT
# coding: utf-8
module Splash
  module Helpers



    def user_root
      return Etc.getpwuid(0).name
    end

    def group_root
      return Etc.getgrgid(0).name
    end

    # facilité pour récupérer les PID depuis une regexp
    # @param [Hash] options
    # @option options [String] :pattern un motif de regexp
    # @option options [Array] :patterns Un tableau de motif de regexp
    # @option options [Bool] :full renvoie tout les details si True
    # @return [String|Array] le PID or tout les détails
    def get_processes(options = {})
      patterns = []
      patterns  = options[:patterns] if options[:patterns]
      patterns << options[:pattern] if options[:pattern]
      res = PS.get_all_processes
      patterns.each do |item|
        res = res.find_processes item
      end
      if options[:full] then
        return res
      else
        return res.pick_attr('PID')
      end
    end


    # facilities to find a file in gem path
    # @param [String] _gem a Gem name
    # @param [String] _file a file relative path in the gem
    # @return [String] the path of the file, if found.
    # @return [False] if not found
    def search_file_in_gem(_gem,_file)
      if Gem::Specification.respond_to?(:find_by_name)
        begin
          spec = Gem::Specification.find_by_name(_gem)
        rescue LoadError
          spec = nil
        end
      else
        spec = Gem.searcher.find(_gem)
      end
      if spec then
        if Gem::Specification.respond_to?(:find_by_name)
          res = spec.lib_dirs_glob.split('/')
        else
          res = Gem.searcher.lib_dirs_for(spec).split('/')
        end
        res.pop
        services_path = res.join('/').concat("/#{_file}")
        return services_path if File::exist?(services_path)
        return false
      else
        return false
      end
    end



    # facilité pour vérifier si le process actif est root
    # @return [Bool] vrai ou faux
    def is_root?
      case (Process.uid)
      when 0
        return true
      else
        return false
      end
    end

    # facilité pour s'assurer qu'on execute une méthode avec les droits root
    # @param [Symbol] method a method name th wrap
    # @return [void] le retour de la méthode wrappée
    def run_as_root(method, options = {})
      unless is_root?
        return {:case => :not_root, :more => "subcommands : #{method.to_s}"}
      else
        return self.send method, options
      end
    end

    # method for daemonize blocks
    # @param [Hash] options the list of options, keys are symbols
    # @option  options [String] :description the description of the process, use for $0
    # @option  options [String] :pid_file the pid filename
    # @option  options [String] :daemon_user the user to change privileges
    # @option  options [String] :daemon_group the group to change privileges
    # @option  options [String] :stderr_trace the path of the file where to redirect STDERR
    # @option  options [String] :stdout_trace the path of the file where to redirect STDOUT
    # @option  options [Proc] :sigint_handler handler Proc for SIGINT signal
    # @option  options [Proc] :sigterm_handler handler Proc for SIGTERM signal
    # @option  options [Proc] :sighup_handler handler Proc for SIGHuP signal
    # @option  options [Bool] :foreground option to run foreground
    # @yield a process definion or block given
    # @example usage inline
    #    class Test
    #      include Splash::Helpers
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
    #      include Splash::Helpers
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

      trap("SIGINT"){
        if options[:sigint_handler] then
          options[:sigint_handler].call
        else
          exit! 0
        end
      }
      trap("SIGTERM"){
        if options[:sigterm_handler] then
          options[:sigterm_handler].call
        else
          exit! 0
        end
       }
      trap("SIGHUP"){
        if options[:sighup_handler] then
          options[:sighup_handler].call
        else
          exit! 0
        end
       }
      if options[:foreground]
        change_logger logger: :dual
        Process.setproctitle options[:description] if options[:description]
        return yield
      end
      fork do
        change_logger logger: :daemon
        #Process.daemon
        File.open(options[:pid_file],"w"){|f| f.puts Process.pid } if options[:pid_file]
        if options[:daemon_user] and options[:daemon_group] then
          uid = Etc.getpwnam(options[:daemon_user]).uid
          gid = Etc.getgrnam(options[:daemon_group]).gid
          Process::UID.change_privilege(uid)
          #  Process::GID.change_privilege(gid)
        end
        $stdout.reopen(options[:stdout_trace], "w") if options[:stdout_trace]
        $stderr.reopen(options[:stderr_trace], "w") if options[:stderr_trace]

        #$0 = options[:description]
        Process.setproctitle options[:description] if options[:description]

        yield

      end
      return 0
    end

    # @!group facilités sur le système de fichier

    # facilité d'installation de fichier
    # @param [Hash] options
    # @option options [String] :source le chemin source du fichier
    # @option options [String] :target le chemin cible du fichier
    # @option options [String] :mode les droits du fichier du type Octal "XXX"
    # @option options [String] :owner le owner du fichier
    # @option options [String] :group le groupe du fichier
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
    # @option options [String] :mode les droits du fichier du type Octal "XXX"
    # @option options [String] :owner le owner du fichier
    # @option options [String] :group le groupe du fichier
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
    # @return [Array] of Symbol with error type : [:inexistant,:mode,:owner,:group]
    # @param [Hash] options
    # @option options [String] :path le répertoire (relatif ou absolut) obligatoire
    # @option options [String] :mode droit du  répertoire optionnel
    # @option options [String] :owner owner du répertoire optionnel
    # @option options [String] :group groupe du répertoire optionnel
    def verify_folder(options ={})
      res = Array::new
      return  [:inexistant] unless File.directory?(options[:name])
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

    # verifier d'existence d'un lien
    # @return [Bool] vrai ou faux
    # @param [Hash] options
    # @option options [String] :name path du lien
    def verify_link(options ={})
      return File.file?(options[:name])
    end

    # verifier d'existence d'un fichier
    # @return [Array] of Symbol with error type : [:inexistant,:mode,:owner,:group]
    # @param [Hash] options
    # @option options [String] :name path du fichier obligatoire
    # @option options [String] :mode droit du fichier optionnel
    # @option options [String] :owner owner du fichier optionnel
    # @option options [String] :group groupe du fichier optionnel
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
