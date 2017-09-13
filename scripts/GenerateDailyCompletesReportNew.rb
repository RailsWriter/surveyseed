require 'csv'

begin
  timetorepeat = true
  count=0
  CSV.open('Reports/Dailycompletes', 'a') do |csv|
    #  csv << "Titles"
    User.where("updated_at > ?", (Time.now - 1440.minutes)).each do |m|
    # User.where("created_at > ?", (Time.now - 1440.minutes)).each do |m|
      @SurveysCompletedArray = m.SurveysCompleted.to_a
      if @SurveysCompletedArray.length > 0 then
        (0..@SurveysCompletedArray.length).each do |i|
          csv << [@SurveysCompletedArray[i]]
          count=count+1
          print @SurveysCompletedArray[i]
          puts
        end
        # csv << [m.country, m.SurveysCompleted.to_a.flatten]
	      # count=count+1
	      # print m.SurveysCompleted
      	# puts
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
  print "Going to sleep for 9 minutes"
  puts
  sleep (9.minutes)
end while timetorepeat