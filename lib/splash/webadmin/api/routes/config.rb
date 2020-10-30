WebAdminApp.get '/api/config/full.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : GET, route : full, format : #{format}"
  config = get_config.full
  obj =  splash_return case: :quiet_exit, :more => "Show internal Splash Config"
  obj[:data] = config
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.get '/api/config/fromfile.?:format?' do
  log = get_logger
  fromfile = {}
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : GET, route : fromfile, format : #{format}"
  config = get_config.config_from_file
  fromfile =  splash_return case: :quiet_exit, :more => "Show config from file"
  fromfile[:data] = config
  content_type format
  format_response(fromfile, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end


WebAdminApp.post '/api/config/addlog.?:format?' do
  log = get_logger
  addlog = {}
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : POST, route : addlog, format : #{format}"
  res = get_config.add_log :record => YAML::load(request.body.read), :type => :logs, :clean => true
  case res[:status]
  when :success
    addlog = splash_return case: :quiet_exit, :more => "add logs"
  when :already_exist
    addlog = splash_return case: :already_exist, :more => "add logs"
  when :failure
    addlog = splash_return case: :configuration_error, :more => "add logs"
    addlog[:data] = res
  end
  content_type format
  format_response(addlog, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end


WebAdminApp.delete '/api/config/deletelog/:label.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : DELETE, route : deletelog, format : #{format}"
  deletelog = {}
  logsrec = Splash::Logs::LogsRecords::new params[:label].to_sym
  logsrec.clear
  res = get_config.delete_log label: params[:label].to_sym
  case res[:status]
  when :success
    deletelog = splash_return case: :quiet_exit, :more => "delete logs"
  when :not_found
    deletelog = splash_return case: :not_found, :more => "delete logs"
  else
    deletelog = splash_return case: :configuration_error, :more => "delete logs"
  end
  content_type format
  format_response(deletelog, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
