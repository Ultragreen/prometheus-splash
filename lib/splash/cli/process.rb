# coding: utf-8

# module for all Thor subcommands
module CLISplash

  # Thor inherited class for Processes management
  class Processes < Thor
    include Splash::Config
    include Splash::Exiter
    include Splash::Processes

    # Thor method : unning Splash configured processes monitors analyse
    desc "analyse", "analyze processes defined in Splash config"
    def analyse
      if is_root? then
        log  = get_logger
        results = ProcessScanner::new
        res = results.analyse
        log.info "Splash Configured process records :"
        full_status = true
        results.output.each do |result|
          if result[:status] == :running then
            log.ok "Process : #{result[:process]} : running"
            log.item "Detected patterns : "
            result[:patterns].each do |pattern|
              log.arrow "/#{pattern}/"
            end
            log.item "CPU usage in % : #{result[:cpu]} "
            log.item "Memory usage in % : #{result[:mem]} "
          else
            log.ko "Process : #{result[:process]} : inexistant"
            log.item "Detected patterns : "
            result[:patterns].each do |pattern|
              log.arrow "/#{pattern}/"
            end
          end

          full_status = false unless result[:status] == :running
        end

        if full_status then
          log.ok "Global status : no error found"
        else
          log.error "Global status : some error found"
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_root, :more => "Process analysis"
      end
    end


    # Thor method : running Splash configured processes monitors analyse and sending to Prometheus Pushgateway
    desc "monitor", "monitor processes defined in Splash config"
    def monitor
      if is_root? then
        log = get_logger
        log.level = :fatal if options[:quiet]
        result = ProcessScanner::new
        result.analyse
        splash_exit result.notify
      else
        splash_exit case: :not_root, :more => "Process analysis"
      end
    end

    # Thor method : display a specific Splash configured process monitor
    desc "show PROCESS", "show Splash configured process record for PROCESS"
    def show(record)
      if is_root? then
        log = get_logger
        process_recordset = get_config.processes.select{|item| item[:process] == record }
        unless process_recordset.empty? then
          record = process_recordset.first
          log.item "Process monitor : #{record[:process]}"
          log.arrow "patterns :"
          record[:patterns].each do |pattern|
            log.flat "   - /#{pattern}/"
          end
          splash_exit case: :quiet_exit
        else
          splash_exit case: :not_found, :more => "Process not configured"
        end
      else
        splash_exit case: :not_root, :more => "Process analysis"
      end
    end

    # Thor method : display the full list of Splash configured processes monitors
    desc "list", "List all Splash configured process records"
    long_desc <<-LONGDESC
    List all Splash configured processes record\n
    with --detail, show process records details
    LONGDESC
    option :detail, :type => :boolean,  :aliases => "-D"
    def list
      if is_root? then
        log = get_logger
        log.info "Splash configured process records :"
        process_recordset = get_config.processes
        log.ko 'No configured process found' if process_recordset.empty?
        process_recordset.each do |record|
          log.item "Process monitor : #{record[:process]}"
          if options[:detail] then
            log.arrow "patterns :"
            record[:patterns].each do |pattern|
              log.flat "   - /#{pattern}/"
            end
          end
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_root, :more => "Process analysis"
      end
    end

    # Thor method : display the full list of Splash configured process monitors
    desc "get_result PROCESS", "Get last or specific process monitoring report"
    long_desc <<-LONGDESC
    Get last or specific process monitoring report\n
    with --date <DATE>, a date format string (same as in history ouput)
    LONGDESC
    option :date, :type => :string,  :aliases => "-D"
    def get_result(process)
      if is_root? then
        log = get_logger
        log.info "Process : #{process}"
        config = get_config
        records = ProcessRecords::new(process).get_all_records
        if options[:date] then
          wanted = records.select{|key,value| key.keys.first == options[:date]}.first
        else
          wanted = records.last
        end
        if wanted.nil? then
          splash_exit case: :not_found, more: "Process never monitored"
        else
          record =wanted.keys.first
          value=wanted[record]
          log.item record
          log.arrow "Status : #{value[:status].to_s}"
          log.arrow "CPU Percent : #{value[:cpu_percent]}"
          log.arrow "MEM Percent : #{value[:mem_percent]}"
        end
      else
        splash_exit case: :not_root, :more => "Process get result"
      end
    end


    # Thor method : show logs monitoring history
    long_desc <<-LONGDESC
    show Process monitoring history for LABEL\n
    LONGDESC
    option :table, :type => :boolean,  :aliases => "-t"
    desc "history PROCESS", "show process monitoring history"
    def history(process)
      if is_root? then
        log = get_logger
        log.info "Process : #{process}"
        config = get_config
        if options[:table] then
          table = TTY::Table.new do |t|
            t << ["Start Date", "Status", "CPU Percent", "MEM Percent"]
            t << ['','','','']
            ProcessRecords::new(process).get_all_records.each do |item|
              record =item.keys.first
              value=item[record]
              t << [record, value[:status].to_s, value[:cpu_percent], value[:mem_percent]]
            end
          end
          if check_unicode_term  then
            puts table.render(:unicode)
          else
            puts table.render(:ascii)
          end

        else
          ProcessRecords::new(process).get_all_records.each do |item|
            record =item.keys.first
            value=item[record]
            log.item record
            log.arrow "Status : #{value[:status].to_s}"
            log.arrow "CPU Percent : #{value[:cpu_percent]}"
            log.arrow "MEM Percent : #{value[:mem_percent]}"
          end
        end
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_root, :more => "Process analysis"
      end
    end

  end

end
