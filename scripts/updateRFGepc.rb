# This script updates old project epc from 0 to the new $0.00 format.

RfgProject.all.each do |project|
  
  if project.epc == "0" then
    project.epc = "$.00"
    puts "Found 0"
  else
  end
    
  project.save
  print "Project: ", project.rfg_id
  puts
end