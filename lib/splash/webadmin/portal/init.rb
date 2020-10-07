Dir[File.dirname(__FILE__) + '/controllers/*.rb'].each {|file| require file  unless File.basename(file) == 'init.rb'}
Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each {|file| require file  unless File.basename(file) == 'init.rb'}

Slim::Engine.set_options pretty: true

def get_menu(current)
  @menu = ['Logs','Processes','Commands','RestCLIENT','Proxy/Links','Documentation']
  @menu_icons = {'Logs' => "file-text",'Processes' => "cogs",'Commands' => 'play-circle-o','RestCLIENT' => "server",'Proxy/Links' => 'random','Documetation' => 'medkit'}
  @current_item = nil
  @current_item = @menu[current] unless current == -1
end
