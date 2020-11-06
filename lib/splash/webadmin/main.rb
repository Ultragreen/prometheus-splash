

class WebAdminApp < Sinatra::Base

  include Splash::Config
  include Splash::Helpers
  include Splash::Exiter
  include Splash::Loggers
  include Splash::Daemon::Controller
  include Splash::Logs
  include Splash::Processes
  include Splash::Transports

  set :server, 'thin'
  set :port, get_config.webadmin_port
  set :bind, get_config.webadmin_ip
  set :static, :enable
  set :public_folder, search_file_in_gem("prometheus-splash", 'lib/splash/webadmin/portal/public')
  set :views, search_file_in_gem("prometheus-splash", "lib/splash/webadmin/portal/views")

  before do
    rehash_config
  end

  def rehash_daemon
    status = get_processes({ :pattern => get_config.daemon_process_name}).empty?
    if status == false then
      transport = get_default_client
      unless transport.class == Hash  and transport.include? :case then
        transport.publish queue: "splash.#{Socket.gethostname}.input",
                          message: { :verb => :reset,
                            :return_to => :ignore,
                            :queue => "splash.#{Socket.gethostname}.input" }.to_yaml
      end
    end
  end

end

require 'splash/webadmin/portal/init'
require 'splash/webadmin/api/routes/init'
