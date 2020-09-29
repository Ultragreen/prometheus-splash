



set :server, 'thin'
set :port, 9234
set :bind, '127.0.0.1'

get '/' do
  'Awesome!'
end
