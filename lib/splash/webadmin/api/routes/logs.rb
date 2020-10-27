



WebAdminApp.get '/api/logs/list.?:format?' do
  log = get_logger
  list = {}
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : GET, route : list, format : #{format}"
  logs_recordset = get_config.logs
  list =  splash_return case: :quiet_exit, :more => "logs list"
  list[:data] = logs_recordset
  content_type format
  format_response(list, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
  end

WebAdminApp.get '/api/logs/show/:name.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : GET, route : show, item : #{params[:name]} , format : #{format}"
  logs_recordset = get_config.logs.select{|item| item[:label] == params[:name].to_sym }
  show = {}
  unless logs_recordset.empty? then
    record = logs_recordset.first
    show = splash_return case: :quiet_exit
    show[:data] = record
  else
    show = splash_return case: :not_found, :more => "logs not configured"
  end
  format_response(show, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/logs/analyse.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : POST, route : analyse, format : #{format}"
  results = Splash::Logs::LogScanner::new
  results.analyse
  res = results.output
  analyse =  splash_return case: :quiet_exit, :more => "logs analyse report"
  analyse[:data] = res
  status 201
  content_type format
  format_response(analyse, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/logs/monitor.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : POST, route : monitor, format : #{format}"
  results = Splash::Logs::LogScanner::new
  results.analyse
  monitor = splash_return results.notify
  if monitor[:status] == :failure then
    status 503
  else
    status 201
  end
  content_type format
  format_response(monitor, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
