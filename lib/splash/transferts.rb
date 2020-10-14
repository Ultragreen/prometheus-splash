# coding: utf-8

# base Splash Module
module Splash

  # Transferts module
  module Transferts

    include Splash::Config
    include Splash::Loggers
    include Splash::Helpers

      def run_txs(options = {})
        cache_path = get_config.transferts[:config][:cache]
        puts 'Running Push Transferts'
        get_config.transferts[:definitions].each do |record|
          unless File::exist?("#{cache_path}/#{record[:name]}.data") then
            puts "#{record[:name]} : Never init"
          end
          puts " * Execute : #{record[:desc]}"
          if [:push,:pull].include? record[:type] then
            Splash::Transferts.send record[:type] , record
          else
              puts "Transfert type unkown"
          end
        end
        return {:case => :quiet_exit }
      end



      def prepare_tx(name)
            log = get_logger
            cache_path = get_config.transferts[:config][:cache]
            record = get_config.transferts[:definitions].select { |item| item[:name] == name }.first
            home  = Etc.getpwnam(record[:local][:user]).dir
            identity = File::readlines("#{home}/.ssh/id_rsa.pub").first.chomp
            folder  = {:mode => "755",
                       :owner => record[:local][:user] ,
                       :group => Etc.getgrgid(Etc.getpwnam(record[:local][:user]).gid).name,
                       :name => record[:local][:path],
                       :path => record[:local][:path]}
            log.info "Ensure local folder : #{record[:local][:path]}"
            make_folder(folder) unless verify_folder(folder).empty?
            begin
              log.info "Ensure RSA Key sharing for local user : #{record[:local][:user]} to remote user : #{record[:remote][:user]}"
              ssh = Net::SSH.start(record[:remote][:host],record[:remote][:user])
              output = ssh.exec!(%[/bin/bash -cl '
                                umask 077;
                                mkdir #{record[:remote][:path]};
                                test -d ~/.ssh || mkdir ~/.ssh;
                                if [ ! -f ~/.ssh/authorized_keys -o `grep "#{identity}" ~/.ssh/authorized_keys 2> /dev/null | wc -l` -eq 0 ]; then
                               echo "#{identity}" >> ~/.ssh/authorized_keys
                               fi'])
              log.info "Prepare remote folder : #{record[:remote][:path]}"
              log.info "Prepare data file for tranfert : #{record[:name]}"
              `echo true > "#{cache_path}/#{record[:name]}.data"`
              return {:case => :quiet_exit }
          rescue Interrupt
            splash_exit case: :interrupt, more: "Remote command exection"
          rescue TTY::Reader::InputInterrupt
            splash_exit case: :interrupt, more: "Remote command exection"
          end
      end



      def save_data

      end



      def self.push(record)
        config = get_config
        scp = Net::SCP.start(record[:remote][:host],record[:remote][:user])
        list = Dir.glob("#{record[:local][:path]}/#{record[:pattern]}")
        puts "Transfering #{list.count} file(s)"
        list.each do|f|
          puts "Copy file : #{f} to #{record[:remote][:user]}@#{record[:remote][:host]}:#{record[:remote][:path]}"
          scp.upload! f, record[:remote][:path]
          if record[:backup] then
            FileUtils::mv(f, "#{f}.#{Time.now.getutc.to_i}")
          else
            FileUtils::unlink(f)
          end
        end
      end

    end
  end
