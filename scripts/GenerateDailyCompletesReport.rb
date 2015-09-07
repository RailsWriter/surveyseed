require 'csv'

begin
  timetorepeat = true
  count=0
  CSV.open('Reports/Dailycompletes', 'a') do |csv|
    #  csv << "Titles"
    User.where("created_at > ?", (Time.now - 720.minutes)).each do |m|
      if m.SurveysCompleted.length > 0 then
        csv << m.SurveysCompleted.to_a.flatten
	      count=count+1
	      print m.SurveysCompleted
      	puts
      else
      end
    end
  end
  print "Number of completes in last 12 hrs: ", count
  puts
  print "Current UTC ", Time.now, "and local time ", Time.now-7*60*60
  puts
  sleep (0.minutes)
end # while timetorepeat