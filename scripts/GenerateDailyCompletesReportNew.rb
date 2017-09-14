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
          if (@SurveysCompletedArray[i][0] >= (Time.now - 1440.minutes)) then
            csv << @SurveysCompletedArray[i].flatten
            count=count+1
            print @SurveysCompletedArray[i].flatten
            puts
          else
          end
        end
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