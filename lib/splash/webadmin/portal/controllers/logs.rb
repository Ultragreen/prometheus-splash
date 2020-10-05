WebAdminApp.get '/' do
  get_menu 1
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/logs/list.yml"
  @raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(@raw)[:data]
  slim :logs, :format => :html
end
