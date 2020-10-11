WebAdminApp.get '/sequences' do
  get_menu 3
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/sequences/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  slim :sequences, :format => :html
end
