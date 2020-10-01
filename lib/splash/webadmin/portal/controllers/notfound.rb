WebAdminApp.not_found do
  get_menu -1
  @path = request.path
  slim :not_found unless request.path =~ /^\/portal/ 
end
