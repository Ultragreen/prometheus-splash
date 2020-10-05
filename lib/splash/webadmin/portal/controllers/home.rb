WebAdminApp.get '/' do
  get_menu -1
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/full.yml"
  @raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(@raw)[:data]
  slim :home, :format => :html
end

WebAdminApp.get '/home' do
  get_menu 0
  slim :home, :format => :html
end
