# coding: utf-8
module CLISplash

  class Logs < Thor
    include Splash::Config
    include Splash::Exiter


    desc "analyse", "analyze logs in config"
    def analyse
      log  = get_logger
      results = Splash::LogScanner::new
      res = results.analyse
      log.info "SPlash Configured logs status :"
      full_status = true
      results.output.each do |result|
        if result[:status] == :clean then
          log.ok "Log : #{result[:log]} : no errors"
          log.item "Detected pattern : #{result[:pattern]}"
          log.item "Nb lines = #{result[:lines]}"
        elsif result[:status] == :missing then
          log.ko "Log : #{result[:log]} : missing !"
          log.item "Detected pattern : #{result[:pattern]}"
        else
          log.ko "Log : #{result[:log]} : #{result[:count]} errors"
          log.item "Detected pattern : #{result[:pattern]}"
          log.item "Nb lines = #{result[:lines]}"
        end

        full_status = false unless result[:status] == :clean
      end
      display_status = (full_status)? "OK": "KO"
      if full_status then
        log.ok "Global status : no error found"
      else
        log.error "Global status : some error found"
      end
      splash_exit case: :quiet_exit
    end

    desc "monitor", "monitor logs in config"
    def monitor
      result = Splash::LogScanner::new
      result.analyse
      result.notify
      splash_exit result.notify

    end

    desc "show LOG", "show configured log monitoring for LOG"
    def show(logrecord)
      log = get_logger
      log_record_set = get_config.logs.select{|item| item[:log] == logrecord }
      unless log_record_set.empty? then
        record = log_record_set.first
        log.info "Splash log monitor : #{record[:log]}"
        log.item "pattern : /#{record[:pattern]}/"
        splash_exit case: :quiet_exit
      else
        splash_exit case: :not_found, :more => "log not configured"
      end
    end

    desc "list", "Show configured logs monitoring"
    long_desc <<-LONGDESC
    Show configured logs monitoring\n
    with --detail, show logs monitor details
    LONGDESC
    option :detail, :type => :boolean
    def list
      log = get_logger
      log.info "Splash configured log monitoring :"
      log_record_set = get_config.logs
      log.ko 'No configured commands found' if log_record_set.empty?
      log_record_set.each do |record|
        log.item "log monitor : #{record[:log]}"
        if options[:detail] then
          log.flat "  ->   pattern : /#{record[:pattern]}/"
        end
      end
      splash_exit case: :quiet_exit
    end

  end

end
