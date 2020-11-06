WebAdminApp.get '/commands/?:status?/?:command?' do
  get_menu 2
  log = get_logger
  log.call "WEB : commands, verb : GET, controller : /commands"
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/commands/list.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(raw)[:data]
  @command_failed = params[:command] if params[:status] == 'failure'
  @command_saved = params[:command] if params[:status] == 'success'
  slim :commands, :format => :html
end

WebAdminApp.get '/get_command_history/:command' do
  get_menu 2
  log = get_logger
  log.call "WEB : commands, verb : GET, controller : /get_command_history/:command"
  @data = {}
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/commands/history/#{params[:command].to_s}.yml"
  raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  res = YAML::load(raw)
  @data = res[:data] if res[:status] == :success
  @command = params[:command].to_s
  slim :command_history, :format => :html
end

WebAdminApp.get '/add_modify_command/?:command?' do
  get_menu 2
  log = get_logger
  log.call "WEB : commands, verb : GET, controller : /add_modify_command/?:command?"
  @data = {}
  if params[:command] then
    url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/commands/show/#{params[:command].to_s}.yml"
    raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
    res = YAML::load(raw)
    @data = res[:data] if res[:status] == :success
    if @data[:retention].class == Hash then
      prov = @data[:retention].flatten.reverse.join(' ')
      @data[:retention] = prov
    end
    if @data[:schedule].class == Hash then
      prov = @data[:schedule].flatten.join(' ')
      @data[:schedule] = prov
    end
    if @data[:delegate_to].class == Hash then
      prov = "#{@data[:delegate_to][:remote_command]}@#{@data[:delegate_to][:host]}"
      @data[:delegate_to] = prov
    end
    @data[:old_command] = params[:command].to_s
  end
  slim :command_form, :format => :html
end


WebAdminApp.post '/save_command' do
  get_menu 2
  log = get_logger
  log.call "WEB : commands, verb : POST, controller : /save_command"
  data = {}
  unless params[:retention].blank?
    value, key = params[:retention].split(' ')
    key = (key.nil?)? :days : key.to_sym
    value = value.to_i
    key = :days if key == :day
    key = :hours if key == :hour
    if [:hours,:days].include? key then
      data[:retention] = {key => value}
    end
  end

  unless params[:schedule].blank?
    key, value = params[:schedule].split(' ')
    key = key.to_sym unless key.nil?
    value = '' if value.nil?
    if [:in,:every,:at].include? key and value.match(/\d+[m,d,s,h]/) then
      data[:schedule] = {key => value }
    end
  end

  unless params[:delegate_to].blank?
    key, value = params[:delegate_to].split('@')
    unless  key.blank? or value.blank? then
      data[:delegate_to] = {:remote_command => key.to_sym, :host => value.to_sym }
    end
  end

  data[:desc] = params[:desc]
  data[:command] = params[:command] unless params[:command].blank?
  data[:on_failure] = params[:on_failure].to_sym unless params[:on_failure].blank?
  data[:on_success] = params[:on_success].to_sym unless params[:on_success].blank?
  data[:user] = params[:user] unless params[:user].blank?
  data[:name] = params[:name].split(' ').first.to_sym
  puts params.to_yaml
  puts data.to_yaml
  redirect "/command/failure/#{params[:name].to_s}" if data[:command].blank? and data[:delegate_to].blank?
  if params[:update] then
    url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/deletecommand/#{params[:old_command]}"
    raw = RestClient::Request.execute(method: 'DELETE', url: url,timeout: 10)
  end
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/addcommand.yml"
  raw = RestClient::Request.execute(method: 'POST', url: url,timeout: 10, payload: data.to_yaml)
  res = YAML::load(raw)
  if res[:status] == :success then
    redirect "/commands/success/#{params[:name].to_s}"
  else
    redirect "/commands/failure/#{params[:name].to_s}"
  end
end
