WebAdminApp.get '/commands' do
  get_menu 2
  log = get_logger
  log.call "WEB : commands, verb : GET, controller : /commands"
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/commands/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  slim :commands, :format => :html
end
