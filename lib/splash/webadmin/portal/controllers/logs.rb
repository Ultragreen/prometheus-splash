WebAdminApp.get '/logs' do
  get_menu 0
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/logs/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/logs/analyse.yml"
  raw = RestClient::Request.execute(method: 'POST', url: url,timeout: 10)
  prov = YAML::load(raw)[:data]
  @result = {}
  prov.each {|item|
    @result[item[:label]] = item
  }
  slim :logs, :format => :html
end
