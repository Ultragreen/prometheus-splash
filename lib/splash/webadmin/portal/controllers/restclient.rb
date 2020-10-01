WebAdminApp.get '/restclient' do
  get_menu 3
  slim :restclient,  :format => :html
end

WebAdminApp.post '/restclient/query' do
  @method = params[:method]
  @url = params[:url]
  @notfound = false
  begin
    @result = RestClient::Request.execute(method: @method.to_sym, url: @url,timeout: 10)
  rescue SocketError
    @result = false
  rescue RestClient::NotFound => e
    @notfound = true
    @result = e.response
  end
  slim :restclient_result,  :format => :html, :layout => false
end
