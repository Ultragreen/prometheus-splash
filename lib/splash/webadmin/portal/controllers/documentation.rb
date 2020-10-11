WebAdminApp.get '/documentation' do
  get_menu 6
    filename = search_file_in_gem("prometheus-splash","README.md")
    @data = Kramdown::Document.new(File::readlines(filename).join).to_html
    slim :documentation, :format => :html
end
