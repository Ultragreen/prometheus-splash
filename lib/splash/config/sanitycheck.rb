# coding: utf-8
module Splash
  module ConfigUtilities
    include Splash::Constants



    # Sanitycheck action method for testing installation of Splash
    # @return [Integer] an errorcode value
    def checkconfig(options ={})
      self.extend Splash::Loggers
      log = get_logger
      log.info "Splash -> sanitycheck : "
      config = get_config
      full_res = 0
      res = verify_file(name: CONFIG_FILE, mode: "644", owner: config.user_root, group: config.group_root)
      target = "Config file : #{CONFIG_FILE}"
      if res.empty? then
        log.ok target
      else
        log.ko target
        full_res =+ 1
        log.flat "    pbm => #{res.map {|p| p.to_s}.join(',')}"
      end

      target = "PID Path : #{config[:pid_path]}"
      res = verify_folder(name: config[:pid_path], mode: "644", owner: config.user_root, group: config.group_root)
      if res.empty? then
        log.ok target
      else
        log.ko target
        full_res =+ 1
        log.flat "    pbm => #{res.map {|p| p.to_s}.join(',')}"

      end

      target =  "Trace Path : #{config[:trace_path]}"
      res = verify_folder(name: config[:trace_path], mode: "644", owner: config.user_root, group: config.group_root)
      if res.empty? then
        log.ok target
      else
        log.ko target
        full_res =+ 1
        log.flat "    pbm => #{res.map {|p| p.to_s}.join(',')}"
      end

      target = "Prometheus PushGateway Service running"
      if verify_service host: config.prometheus_pushgateway_host ,port: config.prometheus_pushgateway_port then
        log.ok target
      else
        log.ko target
        full_res =+ 1
      end

      if full_res > 0 then
        log.error "#{full_res} errors occured"
        return { :case => :splash_sanitycheck_error }
      else
        return { :case => :splash_sanitycheck_success}
      end
    end
  end
end
