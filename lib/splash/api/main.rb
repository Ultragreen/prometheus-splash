require 'sinatra'
require 'dependencies'


$-w = nil

include Splash::Dependencies
include Splash::Helpers
include Splash::Exiter
include Splash::Loggers
include Splash::Config

set :server, 'thin'
set :port, 9234
set :bind, '127.0.0.1'

get '/' do
  'Awesome!'
end
