# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for transferts management
  class Transferts < Thor
    include Splash::Transferts
    include Splash::Helpers
    include Splash::Exiter
    include Splash::Loggers



    # Thor method : running tranferts prepare
    long_desc <<-LONGDESC
    Prepare tranferts with RSA Public key\n
    Warning : interactive command only (prompt for passwd)
    LONGDESC
    desc "prepare", "Prepare tranferts with RSA Public key"
    def prepare(name)
      acase = run_as_root :prepare_tx, name
      splash_exit acase
    end

    # Thor method : Execute all tranferts
    long_desc <<-LONGDESC
    Execute all tranferts\n
    Warning : interactive command only (prompt for passwd)
    LONGDESC
    desc "full_execute", "Execute all tranferts"
    def full_execute
      acase = run_as_root :run_txs
      splash_exit acase
    end


    # Thor method : display a specific Splash configured transfert
    desc "show LOG", "show Splash configured transfert TRANSFERT"
    def show(transfert)
      log = get_logger
      transfert_record_set = get_config.tansferts.select{|item| item[:name] == transfert.to_sym }
      unless transfert_record_set.empty? then
        record = transfert_record_set.first
        log.info "Splash transfert : #{record[:name]}"
        log.item "Description : /#{record[:desc]}/"
        log.item "Type : #{record[:type].to_s}"
        log.item "Backup file after copy : #{record[:backup].to_s}"
        log.item "Local spool"
        log.arrow "Path : #{record[:local][:path]}"
        log.arrow "User : #{record[:local][:user]}"
        log.item "Remote spool"
        log.arrow "Path : #{record[:remote][:path]}"
        log.arrow "User : #{record[:remote][:user]}"
        log.arrow "Host : #{record[:remote][:host]}"
        log.item "Post execution"
        log.arrow "Remote command : #{record[:post][:remote_command]}" unless record[:post][:remote_command].nil?
        log.arrow "Local command : #{record[:post][:local_command]}" unless record[:post][:local_command].nil?
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => "log not configured"
      end
    end

    # Thor method : display the full list of Splash configured transferts
    desc "list", "List all Splash configured tranferts"
    long_desc <<-LONGDESC
    Show configured tranferts\n
    with --detail, show transferts details
    LONGDESC
    option :detail, :type => :boolean,  :aliases => "-D"
    def list
      log = get_logger
      log.info "Splash configured transfert :"
      tx_record_set = get_config.logs
      log.ko 'No configured transferts found' if tx_record_set.empty?
      tx_record_set.each do |record|
        log.item "Transfert : #{record[:name]} Description : #{record[:desc]}"
        if options[:detail] then
          log.item "Type : #{record[:type].to_s}"
          log.item "Backup file after copy : #{record[:backup].to_s}"
          log.item "Local spool"
          log.arrow "Path : #{record[:local][:path]}"
          log.arrow "User : #{record[:local][:user]}"
          log.item "Remote spool"
          log.arrow "Path : #{record[:remote][:path]}"
          log.arrow "User : #{record[:remote][:user]}"
          log.arrow "Host : #{record[:remote][:host]}"
          log.item "Post execution"
          log.arrow "Remote command : #{record[:post][:remote_command]}" unless record[:post][:remote_command].nil?
          log.arrow "Local command : #{record[:post][:local_command]}" unless record[:post][:local_command].nil?
        end
      end
      splash_exit case: :quiet_exit
    end

  end


  end

end
