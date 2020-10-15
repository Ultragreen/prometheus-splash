WebAdminApp.get '/' do
  get_menu -1
  url = "http://#{get_config.webadmin_ip}:#{get_config.webadmin_port}/api/config/full.yml"
  @raw = RestClient::Request.execute(method: 'GET', url: url,timeout: 10)
  @data = YAML::load(@raw)[:data]
  @status = get_processes({ :pattern => get_config.daemon_process_name}).empty?
  slim :home, :format => :html
end

WebAdminApp.get '/home' do
  get_menu 0
  slim :home, :format => :html
end

WebAdminApp.get '/daemon/:action' do
  content_type :text

  case params[:action]
  when 'start'
    startdaemon scheduling: true, purge: false
    return 'start'
  when 'stop'
    stopdaemon
    return 'stop'
  when 'restart'
    stopdaemon
    startdaemon scheduling: true, purge: false
    return 'start'
  else
  end
end
