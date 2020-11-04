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
  res = get_config.add_record :record => YAML::load(request.body.read), :key => :label, :type => :logs, :clean => true
  case res[:status]
  when :success
    addlog = splash_return case: :quiet_exit, :more => "add log done"
  when :already_exist
    addlog = splash_return case: :already_exist, :more => "add log twice nto allowed"
  when :failure
    addlog = splash_return case: :configuration_error, :more => "add log failed"
    addlog[:data] = res
  end
  content_type format
  format_response(addlog, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/config/addprocess.?:format?' do
  log = get_logger
  addprocess = {}
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : POST, route : addprocess, format : #{format}"
  res = get_config.add_record :record => YAML::load(request.body.read), :type => :processes, :key => :process, :clean => true
  case res[:status]
  when :success
    addprocess = splash_return case: :quiet_exit, :more => "add process done"
  when :already_exist
    addprocess = splash_return case: :already_exist, :more => "add process twice not allowed"
  when :failure
    addprocess = splash_return case: :configuration_error, :more => "add process failed"
    addprocess[:data] = res
  end
  content_type format
  format_response(addprocess, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.post '/api/config/addcommand.?:format?' do
  log = get_logger
  addcommand = {}
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : POST, route : addcommand, format : #{format}"
  res = get_config.add_record :record => YAML::load(request.body.read), :type => :commands, :key => :name, :clean => true
  case res[:status]
  when :success
    addcommand = splash_return case: :quiet_exit, :more => "add command done"
  when :already_exist
    addcommand = splash_return case: :already_exist, :more => "add command twice not allowed"
  when :failure
    addpraddcommandocess = splash_return case: :configuration_error, :more => "add command failed"
    addcommand[:data] = res
  end
  content_type format
  format_response(addcommand, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end



WebAdminApp.delete '/api/config/deletelog/:label.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : DELETE, route : deletelog, format : #{format}"
  deletelog = {}
  logsrec = Splash::Logs::LogsRecords::new params[:label].to_sym
  logsrec.clear
  res = get_config.delete_record :type => :logs, key: :label, label: params[:label].to_sym
  case res[:status]
  when :success
    deletelog = splash_return case: :quiet_exit, :more => "delete log done"
  when :not_found
    deletelog = splash_return case: :not_found, :more => "nothing done for logs"
  else
    deletelog = splash_return case: :configuration_error, :more => "delete log failed"
  end
  content_type format
  format_response(deletelog, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.delete '/api/config/deleteprocess/:process.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : DELETE, route : deleteprocess, format : #{format}"
  deleteprocess = {}
  procrec = Splash::Processes::ProcessRecords::new params[:process].to_sym
  procrec.clear
  res = get_config.delete_record :type => :processes, :key => :process, process: params[:process].to_sym
  case res[:status]
  when :success
    deleteprocess = splash_return case: :quiet_exit, :more => "delete process done"
  when :not_found
    deleteprocess = splash_return case: :not_found, :more => "nothing done for processes"
  else
    deleteprocess = splash_return case: :configuration_error, :more => "delete process failed"
  end
  content_type format
  format_response(deleteprocess, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end

WebAdminApp.delete '/api/config/deletecommand/:command.?:format?' do
  log = get_logger
  format = (params[:format])? format_by_extensions(params[:format]) : format_by_extensions('json')
  log.call "API : config, verb : DELETE, route : deletecommand, format : #{format}"
  deletecommand = {}
  cmdrec = Splash::Commands::CmdRecords::new params[:command].to_sym
  cmdcrec.clear
  res = get_config.delete_record :type => :commands, :key => :name, name: params[:process].to_sym
  case res[:status]
  when :success
    deletecommand = splash_return case: :quiet_exit, :more => "delete command done"
  when :not_found
    deletecommand = splash_return case: :not_found, :more => "nothing done for commands"
  else
    deletecommand = splash_return case: :configuration_error, :more => "delete command failed"
  end
  content_type format
  format_response(deletecommand, (params[:format])? format_by_extensions(params[:format]): request.accept.first)
end
