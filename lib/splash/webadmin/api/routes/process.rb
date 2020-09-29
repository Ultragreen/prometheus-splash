get '/api/process/list.?:format?' do
  process_recordset = get_config.processes.select{|item| item[:process] == record }
  obj =  splash_exit case: :quiet_exit, :more => "Process analyse report"
  obj[:data] = process_recordset
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

get '/api/process/show/:name.?:format?' do
  process_recordset = get_config.processes.select{|item| item[:process] == record }
  unless process_recordset.empty? then
    record = process_recordset.first
    obj = splash_exit case: :quiet_exit
    obj[:data] = record
  else
    obj = splash_exit case: :not_found, :more => "Process not configured"
  end
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

post '/api/process/analyse.?:format?' do
  results = ProcessScanner::new
  res = results.analyse
  obj =  splash_exit case: :quiet_exit, :more => "Process analyse report"
  obj[:data] = results
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
