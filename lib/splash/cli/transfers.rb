# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for transfers management
  class Transfers < Thor
    include Splash::Transfers
    include Splash::Helpers
    include Splash::Exiter
    include Splash::Loggers



    # Thor method : running transfer prepare
    long_desc <<-LONGDESC
    Prepare transfer with RSA Public key for NAME\n
    Warning : interactive command only (prompt for passwd)
    LONGDESC
    desc "prepare", "Prepare transfers with RSA Public key"
    def prepare(name)
      acase = run_as_root :prepare_tx, name
      splash_exit acase
    end

    # Thor method : Execute all tranferts
    long_desc <<-LONGDESC
    Execute all transfers\n
    Warning : interactive command only (prompt for passwd)
    LONGDESC
    desc "full_execute", "Execute all transfers"
    def full_execute
      acase = run_as_root :run_txs
      splash_exit acase
    end


    # Thor method : display a specific Splash configured transfer
    desc "show LOG", "show Splash configured transfer TRANSFER"
    def show(transfer)
      log = get_logger
      transfer_record_set = get_config.transfers.select{|item| item[:name] == transfer.to_sym }
      unless transfer_record_set.empty? then
        record = transfer_record_set.first
        log.info "Splash transfer : #{record[:name]}"
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

    # Thor method : display the full list of Splash configured transfers
    desc "list", "List all Splash configured transfers"
    long_desc <<-LONGDESC
    Show configured transfers\n
    with --detail, show transfers details
    LONGDESC
    option :detail, :type => :boolean,  :aliases => "-D"
    def list
      log = get_logger
      log.info "Splash configured transfer :"
      tx_record_set = get_config.transfers
      log.ko 'No configured transfers found' if tx_record_set.empty?
      tx_record_set.each do |record|
        log.item "Transfer : #{record[:name]} Description : #{record[:desc]}"
        if options[:detail] then
          log.arrow "Type : #{record[:type].to_s}"
          log.arrow "Backup file after copy : #{record[:backup].to_s}"
          log.arrow "Local spool"
          log.flat "   * Path : #{record[:local][:path]}"
          log.flat "   * User : #{record[:local][:user]}"
          log.arrow "Remote spool"
          log.flat "   * Path : #{record[:remote][:path]}"
          log.flat "   * User : #{record[:remote][:user]}"
          log.flat "   * Host : #{record[:remote][:host]}"
          log.arrow "Post execution"
          log.flat "   * Remote command : #{record[:post][:remote_command]}" unless record[:post][:remote_command].nil?
          log.flat "   * Local command : #{record[:post][:local_command]}" unless record[:post][:local_command].nil?
        end
      end
      splash_exit case: :quiet_exit
    end

  end

end
