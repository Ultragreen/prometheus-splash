

WebAdminApp.use Rack::ReverseProxy do
  reverse_proxy /^\/pushgateway\/?(.*)$/, get_config.prometheus_pushgateway_url + '/'
  reverse_proxy_options preserve_host: true
end


WebAdminApp.use Rack::ReverseProxy do
  reverse_proxy /^\/prometheus\/?(.*)$/, get_config.prometheus_url + '/'
  reverse_proxy_options preserve_host: true
end


WebAdminApp.use Rack::ReverseProxy do
  reverse_proxy /^\/alertmanager\/?(.*)$/, get_config.prometheus_alertmanager_url + '/'
  reverse_proxy_options preserve_host: true
end

WebAdminApp.get '/proxy/links' do
  get_menu 5
  log = get_logger
  log.call "WEB : proxy, verb : GET, controller : /proxy/links"
  config = get_config
  if config.webadmin_proxy == true then
    @proxy = true
    @pushgateway_url = "http://#{config.webadmin_ip}:#{config.webadmin_port}/pushgateway"
    @prometheus_url = "http://#{config.webadmin_ip}:#{config.webadmin_port}/prometheus"
    @alertmanager_url = "http://#{config.webadmin_ip}:#{config.webadmin_port}/prometheus"
  else
    @proxy = false
    @pushgateway_url = "#{config.prometheus_pushgateway_url}"
    @alertmanager_url = "#{config.prometheus_alertmanager_url}"
    @prometheus_url = "#{config.prometheus_url}"
  end
  slim :proxy, :format => :html
end
