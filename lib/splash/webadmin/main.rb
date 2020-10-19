

class WebAdminApp < Sinatra::Base

  include Splash::Config
  include Splash::Helpers
  include Splash::Exiter
  include Splash::Loggers
  include Splash::Daemon::Controller

  set :server, 'thin'
  set :port, get_config.webadmin_port
  set :bind, get_config.webadmin_ip
  set :static, :enable
  set :public_folder, search_file_in_gem("prometheus-splash", 'lib/splash/webadmin/portal/public')
  set :views, search_file_in_gem("prometheus-splash", "lib/splash/webadmin/portal/views")

  before do
    rehash_config
  end



end

require 'splash/webadmin/portal/init'
require 'splash/webadmin/api/routes/init'
