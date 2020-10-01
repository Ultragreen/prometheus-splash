WebAdminApp.get '/' do
  get_menu -1
  slim :home, :format => :html
end

WebAdminApp.get '/home' do
  get_menu 0
  slim :home, :format => :html
end
