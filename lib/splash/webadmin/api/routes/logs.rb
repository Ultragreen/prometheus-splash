



WebAdminApp.get '/api/logs/list.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : GET, route : list, format : #{format}"
  logs_recordset = get_config.logs
  obj =  splash_return case: :quiet_exit, :more => "logses list"
  obj[:data] = logs_recordset
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
  end

WebAdminApp.get '/api/logs/show/:name.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : GET, route : show, item : #{params[:name]} , format : #{format}"
  logs_recordset = get_config.logs.select{|item| item[:label] == params[:name].to_sym }
  unless logs_recordset.empty? then
    record = logs_recordset.first
    obj = splash_return case: :quiet_exit
    obj[:data] = record
  else
    obj = splash_return case: :not_found, :more => "logs not configured"
  end
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/logs/analyse.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : POST, route : analyse, format : #{format}"
  results = Splash::Logs::LogScanner::new
  results.analyse
  res = results.output
  obj =  splash_return case: :quiet_exit, :more => "logs analyse report"
  obj[:data] = res
  status 201
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/logs/monitor.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : logs, verb : POST, route : monitor, format : #{format}"
  results = Splash::Logs::LogScanner::new
  results.analyse
  res = splash_return results.notify
  if res[:status] == :failure then
    status 503
  else
    status 201
  end
  format_response(res, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
