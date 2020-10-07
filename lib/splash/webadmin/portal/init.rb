Dir[File.dirname(__FILE__) + '/controllers/*.rb'].each {|file| require file  unless File.basename(file) == 'init.rb'}
Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each {|file| require file  unless File.basename(file) == 'init.rb'}

Slim::Engine.set_options pretty: true

def get_menu(current)
  @menu = ['Logs','Processes','Commands','RestCLIENT']
  @menu.push 'Proxy' if get_config.webadmin_proxy == true
  @current_item = nil
  @current_item = @menu[current] unless current == -1
end
