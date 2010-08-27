require 'rubygems'  
require 'rake'  
require 'echoe'  
   
Echoe.new('drc_client', '0.1.0') do |p|  
  p.description     = "Rails client for DeRoseConnect"  
  p.url             = "http://github.com/dwaynemac/drc_client"  
  p.author          = "Dwayne Macgowan"  
  p.email           = "dwaynemac@gmail.com"  
#  p.ignore_pattern  = ["tmp/*", "script/*"]  
  p.development_dependencies = ['rubycas-client']  
end  
   
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }  
