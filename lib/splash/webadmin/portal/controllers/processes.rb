WebAdminApp.get '/processes' do
  get_menu 1
  log = get_logger
  log.call "WEB : processes, verb : GET, controller : /processes"
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/process/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/process/analyse.yml"
  raw = RestClient::Request.execute(method: 'POST', url: url,timeout: 10)
  prov = YAML::load(raw)[:data]
  @result = {}
  prov.each {|item|
    @result[item[:process]] = item
  }
  slim :processes, :format => :html
end
