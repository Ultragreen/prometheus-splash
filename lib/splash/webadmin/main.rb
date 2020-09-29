




class WebAdminApp < Sinatra::Base

  set :server, 'thin'
  set :port, 9234
  set :bind, '127.0.0.1'

  include Splash::Config
  include Splash::Exiter
  include Splash::Processes

  require 'splash/webadmin/routes/init'

  get '/' do
    'SPLASH Admin'
  end

  get '/api' do
      'SPLASH API'
  end

end

WebAdminApp.run!
