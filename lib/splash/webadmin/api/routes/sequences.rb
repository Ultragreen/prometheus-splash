



WebAdminApp.get '/api/sequences/list.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : sequences, verb : GET, route : list, format : #{format}"
  obj =  splash_return case: :quiet_exit, :more => "Sequences list"
  obj[:data] = get_config.sequences
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
  end

WebAdminApp.get '/api/sequences/show/:name.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : sequences, verb : GET, route : show, item : #{params[:name]} , format : #{format}"
  sequences_recordset = get_config.sequences[params[:name].to_sym]
  unless sequences_recordset.nil? then
    obj = splash_return case: :quiet_exit
    obj[:data] = sequences_recordset
  else
    obj = splash_return case: :not_found, :more => "Sequence not configured"
  end
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
