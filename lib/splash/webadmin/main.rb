

class WebAdminApp < Sinatra::Base

  set :server, 'thin'
  set :port, 9234
  set :bind, '127.0.0.1'

  include Splash::Config
  include Splash::Helpers
  include Splash::Exiter
  include Splash::Loggers


  get '/' do
    'SPLASH Admin'
  end

end

require 'splash/webadmin/api/routes/init'
log = get_logger logger: :web
log.info "Starting Splash WebAdmin" 
WebAdminApp.run!
