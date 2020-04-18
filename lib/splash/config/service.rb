# coding: utf-8


module Splash
  module ConfigUtilities
    include Splash::Constants
    include Splash::Helpers

    def setupsplash(options = {})
      local_service_file = search_file_in_gem "prometheus-splash", "templates/splashd.service"
      config = get_config
      self.extend Splash::Loggers
      log = get_logger
      log.info "Splashd Systemd Service installation"
      service_file = "splashd.service"
      systemd_path = "/etc/systemd/system"
      return { :case => :options_incompatibility, :more => "Systemd not avaible on this System"} if verify_folder({ :name => systemd_path}) == :inexistant
      log.item "Installing service file : #{service_file} in #{systemd_path}"
      if install_file source: local_service_file, target: "#{systemd_path}/#{service_file}", mode: "755", owner: config.user_root, group: config.group_root then
        return { :case => :quiet_exit, :more => "Splashd Systemd service installed" }
      else
        return { :case => :error_exit, :more = > "Splashd Systemd service could not be installed" }
      end
    end
  end
end
