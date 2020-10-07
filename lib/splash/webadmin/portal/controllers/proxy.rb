

WebAdminApp.use Rack::ReverseProxy do
  config = get_config
  url = "http://#{config.prometheus_pushgateway_host}:#{config.prometheus_pushgateway_port}/#{config.prometheus_pushgateway_path}"
  reverse_proxy /^\/pushgateway\/?(.*)$/, url
  reverse_proxy_options preserve_host: true
end


WebAdminApp.use Rack::ReverseProxy do
  reverse_proxy /^\/prometheus\/?(.*)$/, get_config.prometheus_url
  reverse_proxy_options preserve_host: true
end

WebAdminApp.get '/proxy/links' do
  get_menu 4

  config = get_config
  if config.webadmin_proxy == true then
    @proxy = true
    @pushgateway_url = "http://#{config.webadmin_ip}:#{config.webadmin_port}/pushgateway"
    @prometheus_url = "http://#{config.webadmin_ip}:#{config.webadmin_port}/prometheus"
  else
    @proxy = false
    @pushgateway_url = "http://#{config.prometheus_pushgateway_host}:#{config.prometheus_pushgateway_port}/#{config.prometheus_pushgateway_path}"
    @prometheus_url = "http://#{config.prometheus_url}"
  end
  slim :proxy, :format => :html
end
