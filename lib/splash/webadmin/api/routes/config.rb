WebAdminApp.get '/api/config/full.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "api : config, verb : GET, route : show, format : #{format}"
  config = get_config.full
  obj =  splash_return case: :quiet_exit, :more => "logses list"
  obj[:data] = config
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
