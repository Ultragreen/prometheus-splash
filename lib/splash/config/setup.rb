
# coding: utf-8


module Splash
  module ConfigUtilities
    include Splash::Constants
    include Splash::Helpers
    # Setup action method for installing Splash
    # @return [Integer] an errorcode value
    def setupsplash(options = {})
      conf_in_path = search_file_in_gem "prometheus-splash", "config/splash.yml"
      full_res = 0
      puts "Splash -> setup : "
      unless options[:preserve] then
        print "* Installing Configuration file : #{CONFIG_FILE} : "
        # TODO TTY plateform
        if install_file source: conf_in_path, target: CONFIG_FILE, mode: "644", owner: user_root, group:  group_root then
          puts "[OK]"
        else
          full_res =+ 1
          puts "[KO]"
        end
      else
        puts "Config file preservation."
      end
      config = get_config
      report_in_path = search_file_in_gem "prometheus-splash", "templates/report.txt"
      print "* Installing template file : #{config.execution_template_path} : "
      if install_file source: report_in_path, target: config.execution_template_path, mode: "644", owner: config.user_root, group: config.group_root then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      print "* Creating/Checking pid file path : #{config[:pid_path]} : "
      if make_folder path: config[:pid_path], mode: "644", owner: config.user_root, group: config.group_root then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      print "* Creating/Checking trace file path : #{config[:trace_path]} : "
      if make_folder path: config[:trace_path], mode: "644", owner: config.user_root, group: config.group_root then
        puts "[OK]"
      else
        full_res =+ 1
        puts "[KO]"
      end

      if full_res > 0 then
        $stderr.puts " => #{full_res} errors occured"
        return { :case => :splash_setup_error}
      else
        return { :case => :splash_setup_success }
      end

    end
  end
end
