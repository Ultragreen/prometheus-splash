

class WebAdminApp < Sinatra::Base

  set :server, 'thin'
  set :port, 9234
  set :bind, '127.0.0.1'
  set :static, :enable
  set :public_folder, 'lib/splash/webadmin/portal/public'
  set :views, "lib/splash/webadmin/portal/views"

  include Splash::Config
  include Splash::Helpers
  include Splash::Exiter
  include Splash::Loggers



end

require 'splash/webadmin/portal/init'
require 'splash/webadmin/api/routes/init'
log = get_logger logger: :web, force: true
log.info "Starting Splash WebAdmin"
WebAdminApp.run!
