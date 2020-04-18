module CLISplash

  class Processes < Thor
    include Splash::Config
    include Splash::Exiter
    include Splash::Processes

    desc "analyse", "analyze processes defined in Splash config"
    def analyse
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
    end

    desc "monitor", "monitor processes defined in Splash config"
    def monitor
      log = get_logger
      log.level = :fatal if options[:quiet]
      result = ProcessScanner::new
      result.analyse
      splash_exit result.notify
    end

    desc "show PROCESS", "show Splash configured process record for PROCESS"
    def show(record)
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
    end

    desc "list", "List all Splash configured process records"
    long_desc <<-LONGDESC
    List all Splash configured processes record\n
    with --detail, show process records details
    LONGDESC
    option :detail, :type => :boolean,  :aliases => "-D"
    def list
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
    end

  end

end
