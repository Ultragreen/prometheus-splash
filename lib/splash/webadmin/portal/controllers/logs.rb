WebAdminApp.get '/logs/?:status?/?:label?' do
  get_menu 0
  log = get_logger
  log.call "WEB : logs, verb : GET, controller : /logs/?:status?/?:label?"
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/logs/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/logs/analyse.yml"
  raw = RestClient::Request.execute(method: 'POST', url: url,timeout: 10)
  prov = YAML::load(raw)[:data]
  @result = {}
  @log_failed = params[:label] if params[:status] == 'failure'
  @log_saved = params[:label] if params[:status] == 'success'
  prov.each {|item|
    @result[item[:label]] = item
  }
  slim :logs, :format => :html
end


WebAdminApp.get '/add_modify_log/?:label?' do
  get_menu 0
  log = get_logger
  log.call "WEB : logs, verb : GET, controller : /add_modify_log/?:label?"
  @data = {}
  if params[:label] then
    url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/logs/show/#{params[:label].to_s}.yml"
    raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
    res = YAML::load(raw)
    @data = res[:data] if res[:status] == :success
    @data[:old_label] = params[:label].to_s
  end
  slim :logs_form, :format => :html
end


WebAdminApp.get '/history/:label' do
  get_menu 0
  log = get_logger
  log.call "WEB : logs, verb : GET, controller : /history/:label"
  @data = {}
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/logs/history/#{params[:label].to_s}.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  res = YAML::load(raw)
  @data = res[:data] if res[:status] == :success
  @label = params[:label].to_s
  slim :logs_history, :format => :html
end

WebAdminApp.post '/save_log' do
  get_menu 0
  log = get_logger
  log.call "WEB : logs, verb : POST, controller : /save_log/?:label?"
  data = {}
  data[:log] = params[:log]
  data[:pattern] = params[:pattern]
  data[:label] = params[:label].to_sym
  if params[:update] then
    url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/deletelog/#{params[:old_label]}"
    raw = RestClient::Request.execute(method: 'DELETE', url: url,timeout: 10)
  end
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/addlog.yml"
  raw = RestClient::Request.execute(method: 'POST', url: url,timeout: 10, payload: data.to_yaml)
  res = YAML::load(raw)
  if res[:status] == :success then
    redirect "/logs/success/#{params[:label].to_s}"
  else
    redirect "/logs/failure/#{params[:label].to_s}"
  end
end
