WebAdminApp.get '/sequences' do
  get_menu 3
  log = get_logger
  log.call "WEB : sequences, verb : GET, controller : /sequences"
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/sequences/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  slim :sequences, :format => :html
end
