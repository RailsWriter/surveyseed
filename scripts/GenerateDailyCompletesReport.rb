require 'csv'

begin
  timetorepeat = true
  count=0
  CSV.open('Reports/Dailycompletes', 'a') do |csv|
    #  csv << "Titles"
    User.where("created_at > ?", (Time.now - 1440.minutes)).each do |m|
      if m.SurveysCompleted.length > 0 then
        csv << [m.country, m.SurveysCompleted.to_a.flatten]
	      count=count+1
	      print m.SurveysCompleted
      	puts
      else
      end
    end
  end
  print "Number of completes in last 24 hrs: ", count
  puts
  print "UTC time ", Time.now
  puts
  print "Local time ", Time.now-7*60*60
  puts
  print "Going to sleep for 10 minutes"
  puts
  sleep (10.minutes)
end while timetorepeat