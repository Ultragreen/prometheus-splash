# coding: utf-8

# base Splash Module
module Splash

  # Transferts module
  module Transferts

    include Splash::Config
    include Splash::Loggers
    include Splash::Helpers
    include Splash::Backends

    def run_txs(options = {})
      log = get_logger
      backend = get_backend :transferts_trace
      log.info 'Running Push Transferts'
      count=0
      get_config.transferts.each do |record|
        log.item " * Execute : #{record[:name]},  #{record[:desc]}"        
        unless backend.exist? key: record[:name] then
          log.warn "#{record[:name]} : Never init"
        end
        
        if [:push,:pull].include? record[:type] then
          count += 1 unless Splash::Transferts.send record[:type] , record
        else
          log.ko "Transfert type unkown"
          count += 1
        end
      end
      return {:case => :error_exit, :more => "#{count} Transfert(s) failed"} if count > 0
      return {:case => :quiet_exit }
    end
    
    
    
    def prepare_tx(name)
      log = get_logger
      record = get_config.transferts.select { |item| item[:name] == name.to_sym }.first
      home  = Etc.getpwnam(record[:local][:user]).dir
      identity = ::File::readlines("#{home}/.ssh/id_rsa.pub").first.chomp
      folder  = {:mode => "755",
                 :owner => record[:local][:user] ,
                 :group => Etc.getgrgid(Etc.getpwnam(record[:local][:user]).gid).name,
                 :name => record[:local][:path],
                 :path => record[:local][:path]}
      log.info "Ensure local folder : #{record[:local][:path]}"
      make_folder(folder) unless verify_folder(folder).empty?
      begin
        log.info "Ensure RSA Key sharing for local user : #{record[:local][:user]} to remote user : #{record[:remote][:user]}@#{record[:remote][:host]}"
        ssh = Net::SSH.start(record[:remote][:host],record[:remote][:user])
        output = ssh.exec!(%[
          /bin/bash -cl '
          umask 077;
          mkdir #{record[:remote][:path]};
          test -d ~/.ssh || mkdir ~/.ssh;
          if [ ! -f ~/.ssh/authorized_keys -o `grep "#{identity}" ~/.ssh/authorized_keys 2> /dev/null | wc -l` -eq 0 ]; then              echo "#{identity}" >> ~/.ssh/authorized_keys
          fi'])
        log.info "Prepare remote folder : #{record[:remote][:path]}"
        log.info "Prepare data file for transfert : #{record[:name]}"
        backend = get_backend :transferts_trace
        backend.put key: record[:name], value: 'test'
        log.ok "Transfert : #{record[:name]} prepared successfully"
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
      log = get_logger
      begin
        scp = Net::SCP.start(record[:remote][:host],record[:remote][:user])
        list = Dir.glob("#{record[:local][:path]}/#{record[:pattern]}")
        log.arrow "Transfering #{list.count} file(s)"
        list.each do|f|
          log.arrow "Copy file : #{f} to #{record[:remote][:user]}@#{record[:remote][:host]}:#{record[:remote][:path]}"
          
          scp.upload! f, record[:remote][:path]
          if record[:backup] then
            log.arrow "File #{f} backuped"
            FileUtils::mv(f, "#{f}.#{Time.now.getutc.to_i}")
          else
            FileUtils::unlink(f)
          end
          return true
        end
      rescue
        return false
      end
    end
  end
end
