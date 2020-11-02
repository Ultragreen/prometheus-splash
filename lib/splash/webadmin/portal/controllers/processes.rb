WebAdminApp.get '/processes/?:status?/?:process?' do
  get_menu 1
  log = get_logger
  log.call "WEB : processes, verb : GET, controller : /processes/?:status?/?:process?"
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/process/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/process/analyse.yml"
  raw = RestClient::Request.execute(method: 'POST', url: url,timeout: 10)
  prov = YAML::load(raw)[:data]
  @result = {}
  @log_failed = params[:process] if params[:status] == 'failure'
  @log_saved = params[:process] if params[:status] == 'success'
  prov.each {|item|
    @result[item[:process]] = item
  }
  slim :processes, :format => :html
end

WebAdminApp.get '/add_modify_process/?:process?' do
  get_menu 0
  log = get_logger
  log.call "WEB : processes, verb : GET, controller : /add_modify_process/?:process?"
  @data = {}
  if params[:process] then
    url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/processes/show/#{params[:process].to_s}.yml"
    raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
    res = YAML::load(raw)
    @data = res[:data] if res[:status] == :success
    @data[:old_process] = params[:process].to_s
  end
  slim :process_form, :format => :html
end


WebAdminApp.get '/get_process_history/:process' do
  get_menu 0
  log = get_logger
  log.call "WEB : processes, verb : GET, controller : /get_process_history/:process"
  @data = {}
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/processes/history/#{params[:label].to_s}.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  res = YAML::load(raw)
  @data = res[:data] if res[:status] == :success
  @process = params[:process].to_s
  slim :process_history, :format => :html
end

WebAdminApp.post '/save_process' do
  get_menu 0
  log = get_logger
  log.call "WEB : processes, verb : POST, controller : /save_process/?:process?"
  data = {}
  data[:patterns] = params[:patterns].split(',')
  data[:process] = params[:process].to_sym
  if params[:update] then
    url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/deleteprocess/#{params[:old_process]}"
    raw = RestClient::Request.execute(method: 'DELETE', url: url,timeout: 10)
  end
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/addprocess.yml"
  raw = RestClient::Request.execute(method: 'POST', url: url,timeout: 10, payload: data.to_yaml)
  res = YAML::load(raw)
  if res[:status] == :success then
    redirect "/processes/success/#{params[:process].to_s}"
  else
    redirect "/processes/failure/#{params[:process].to_s}"
  end
end
