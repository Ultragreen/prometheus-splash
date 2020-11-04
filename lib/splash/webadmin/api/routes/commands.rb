



WebAdminApp.get '/api/commands/list.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : commands, verb : GET, route : list, format : #{format}"
  obj =  splash_return case: :quiet_exit, :more => "Commands list"
  obj[:data] = get_config.commands
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
  end

WebAdminApp.get '/api/commands/show/:name.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : commands, verb : GET, route : show, item : #{params[:name]} , format : #{format}"
  commands_recordset = get_config.commands.select {|command| command[:name] == params[:name].to_sym}.first
  unless commands_recordset.nil? then
    obj = splash_return case: :quiet_exit
    obj[:data] = commands_recordset
  else
    obj = splash_return case: :not_found, :more => "Command not configured"
  end
  content_type format
  format_response(obj, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.get '/api/commands/history/:name.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : commands, verb : GET, route : history, format : #{format}"
  record = Splash::Commands::CmdRecords::new(params[:name]).get_all_records
  history =  splash_return case: :quiet_exit, :more => "command monitoring history"
  history[:data] = record
  content_type format
  status 201
  format_response(history, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
