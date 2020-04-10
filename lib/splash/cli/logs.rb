# coding: utf-8
module CLISplash

  class Logs < Thor
    include Splash::Config
    include Splash::Exiter


    desc "analyse", "analyze logs in config"
    def analyse
      results = Splash::LogScanner::new
      res = results.analyse
      puts "SPlash Configured logs status :"
      full_status = true
      results.output.each do |result|
        status = (result[:status] == :clean)? "OK": "KO"
        puts " * Log : #{result[:log]} : [#{status}]"
        puts "   - Detected pattern : #{result[:pattern]}"
        puts "   - detailled Status : #{result[:status].to_s}"
        puts "     count = #{result[:count]}" if result[:status] == :matched
        puts "     nb lines = #{result[:lines]}" if result[:status] != :missing
        full_status = false unless result[:status] == :clean
      end
      display_status = (full_status)? "OK": "KO"
      puts "Global Status : [#{display_status}]"
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
    def show(log)
      log_record_set = get_config.logs.select{|item| item[:log] == log }
      unless log_record_set.empty? then
        record = log_record_set.first
        puts "Splash log monitor : #{record[:log]}"
        puts "  ->   pattern : /#{record[:pattern]}/"
        splash_exit case: :quiet_exit
    else
        splash_exit case: :not_found, :more => "log not configured"
      end
    end

    desc "list", "Show configured logs monitoring"
    long_desc <<-LONGDESC
    Show configured logs monitoring
    with --detail, show logs monitor details
    LONGDESC
    option :detail, :type => :boolean
    def list
      puts "Splash configured log monitoring :"
      log_record_set = get_config.logs
      puts 'No configured commands found' if log_record_set.empty?
      log_record_set.each do |record|
        puts " *  log monitor : #{record[:log]}"
        if options[:detail] then
          puts "  ->   pattern : /#{record[:pattern]}/"
        end
      end
      splash_exit case: :quiet_exit
    end

  end

end
