# coding: utf-8

# base Splash Module
module Splash

  # Transferts module
  module Transferts

    include Splash::Config


      def run_tx
        cache_path = get_config.transferts[:config][:cache]
        puts 'Running Push Transferts'
        get_config.transferts[:definitions].each do |record|
          unless File::exist?("#{cache_path}/#{record[:name]}.data") then
            puts "#{record[:name]} : Never init"
            init_transfert(record)
          end
          puts " * Execute : #{record[:desc]}"
          if [:push,:pull].include? record[:type] then
            Splash::Transfert.send record[:type], record 
          else
              puts "Transfert type unkown"
        end
      end



      def prepare_tx(name)
            cache_path = get_config.transferts[:config][:cache]
            record = get_config.transferts.select { |record| record[:name] == name }.first
            record[:passwd] = get_passwd.to_str
            home  = Etc.getpwnam(record[:local][:user]).dir
            identity = File::readlines("#{home}/.ssh/id_rsa.pub").first.chomp
            ssh = Net::SSH.start(record[:remote][:host],record[:remote][:user] , password: record[:passwd])
            output = ssh.exec!(%[/bin/bash -cl '
                                umask 077;
                                test -d ~/.ssh || mkdir ~/.ssh;
                                if [ ! -f ~/.ssh/authorized_keys -o `grep "#{identity}" ~/.ssh/authorized_keys 2> /dev/null | wc -l` -eq 0 ]; then
                               echo "#{identity}" >> ~/.ssh/authorized_keys
                               fi'])
            `echo true > "#{cache_path}/#{record[:name]}.data"`
      end



      def save_data

      end

      def get_passwd
        prompt = TTY::Prompt.new(active_color: :cyan)
        res = prompt.ask("password:", echo: false, active_color: :cyan)
        return res
      end

      def push(record)
        config = get_config
        scp = Net::SCP.start(record[:remote][:host],record[:remote][:user] , password: record[:passwd])
        list = Dir.glob("#{record[:path]}/#{record[:pattern]}")
        puts "Transfering #{list.count} file(s)"
        list.each do|f|
          puts "Copy file : #{f} to #{record[:remote][:path]}"
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
