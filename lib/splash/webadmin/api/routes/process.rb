



WebAdminApp.get '/api/processes/list.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : processes, verb : GET, route : list, format : #{format}"
  process_recordset = get_config.processes
  obj =  splash_return case: :quiet_exit, :more => "Processes list"
  obj[:data] = process_recordset
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
  end

WebAdminApp.get '/api/processes/show/:name.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : processes, verb : GET, route : show, item : #{params[:name]} , format : #{format}"
  process_recordset = get_config.processes.select{|item| item[:process] == params[:name] }
  unless process_recordset.empty? then
    record = process_recordset.first
    obj = splash_return case: :quiet_exit
    obj[:data] = record
  else
    obj = splash_return case: :not_found, :more => "Process not configured"
  end
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/processes/analyse.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : processes, verb : POST, route : analyse, format : #{format}"
  results = Splash::Processes::ProcessScanner::new
  results.analyse
  res = results.output
  obj =  splash_return case: :quiet_exit, :more => "Process analyse report"
  obj[:data] = res
  status 201
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/processes/monitor.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : processes, verb : POST, route : monitor, format : #{format}"
  results = Splash::Processes::ProcessScanner::new
  results.analyse
  res = splash_return results.notify
  if res[:status] == :failure then
    status 503
  else
    status 201
  end
  content_type format
  format_response(res, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.get '/api/processes/history/:process.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : processes, verb : GET, route : history, format : #{format}"
  record = Splash::Processes::ProcessRecords::new(params[:process]).get_all_records
  history =  splash_return case: :quiet_exit, :more => "Proces monitoring history"
  history[:data] = record
  content_type format
  status 201
  format_response(history, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
