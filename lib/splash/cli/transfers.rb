# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for transfers management
  class Transfers < Thor
    include Splash::Transfers
    include Splash::Helpers
    include Splash::Exiter
    include Splash::Loggers
    include Splash::Transfers


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

    # Thor method : Execute all transfers
    long_desc <<-LONGDESC
    Execute all transfers\n
    Warning : interactive command only (prompt for passwd)
    LONGDESC
    desc "full_execute", "Execute all transfers"
    def full_execute
      acase = run_as_root :run_txs
      splash_exit acase
    end

    # Thor method : Get specific result for a transfers
    long_desc <<-LONGDESC
    Get specific result for a transfers\n
    LONGDESC
    option :date, :type => :string,  :aliases => "-d"
    desc "get_result TRANSFER", "Get specific result for a transfers "
    def get_result(name)
      log = get_logger
      log.item "Transfer : #{name}"
      config = get_config
      data = TxRecords::new(name).get_all_records.select {|record,value| record == options[:date]}.first
      if data.nil? then
        log.ko "Result for #{name} on date #{options[:date]} not found"
        splash_exit case: :not_found, :more => "Result inexistant"
      else
        record = options[:date]
        value = data[record]
        failed = (value[:count].nil? or value[:done].nil?)? 'undef': value[:count].to_i - value[:done].count
        if value[:end_date].nil? then
          log.item "Event : #{record} STATUS : #{value[:status]}"
        else
          log.item "Tx Begin : #{record} => end : #{value[:end_date]} STATUS : #{value[:status]}"
        end
        log.arrow "Tx Time : #{value[:time]}" unless value[:time].nil?
        log.arrow "nb files : #{value[:count]}" unless value[:count].nil?
        unless value[:wanted].nil?
          log.arrow "Files wanted :" unless value[:wanted].empty?
          value[:wanted].each do |file|
            log.flat  "    * #{file}"
          end
        end
        unless value[:done].nil?
          log.arrow "Files done :" unless value[:done].empty?
          value[:done].each do |file|
            log.flat  "    * #{file}"
          end
        end
        unless failed then
          log.arrow "Nb failure : #{failed}"
        end

      end
      splash_exit case: :quiet_exit
    end

    # Thor method : show specfic transfers history
    long_desc <<-LONGDESC
    show transfers history for transfer NAME\n
    LONGDESC
    option :table, :type => :boolean,  :aliases => "-t"
    desc "history", "Show transfers history"
    def history(name)
      log = get_logger
      log.item "Transfer : #{name}"
      config = get_config
      if options[:table] then
        table = TTY::Table.new do |t|
          t << ["Start Date", "End date", "time", "Files count","File count error","Status"]
          t << ['','','','','','']
          TxRecords::new(name).get_all_records.each do |record,value|
            start_date = record
            end_date = (value[:end_date].nil?)? '': value[:end_date]
            time  = (value[:time].nil?)? '': value[:time]
            count = (value[:count].nil?)? '': value[:count]
            failed = (value[:count].nil? or value[:done].nil?)? '': value[:count].to_i - value[:done].count
            status = value[:status]
            t << [start_date, end_date, time, count, failed, status]

          end
        end
        if check_unicode_term  then
          puts table.render(:unicode)
        else
          puts table.render(:ascii)
        end

      else
        TxRecords::new(name).get_all_records.each do |record,value|
          failed = (value[:count].nil? or value[:done].nil?)? 'undef': value[:count].to_i - value[:done].count
          if value[:end_date].nil? then
            log.item "Event : #{record} STATUS : #{value[:status]}"
          else
            log.item "Tx Begin : #{record} => end : #{value[:end_date]} STATUS : #{value[:status]}"
          end
          log.arrow "Tx Time : #{value[:time]}" unless value[:time].nil?
          log.arrow "nb files : #{value[:count]}" unless value[:count].nil?
          unless value[:wanted].nil?
            log.arrow "Files wanted :" unless value[:wanted].empty?
            value[:wanted].each do |file|
              log.flat  "    * #{file}"
            end
          end
          unless value[:done].nil?
            log.arrow "Files done :" unless value[:done].empty?
            value[:done].each do |file|
              log.flat  "    * #{file}"
            end
          end
          unless failed then
            log.arrow "Nb failure : #{failed}"
          end

        end
      end
      splash_exit case: :quiet_exit
    end


    # Thor method : display a specific Splash configured transfer
    desc "show TRANSFER", "show Splash configured transfer TRANSFER"
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
