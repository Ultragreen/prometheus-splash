WebAdminApp.get '/commands' do
  get_menu 0
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/commands/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  slim :commands, :format => :html
end
