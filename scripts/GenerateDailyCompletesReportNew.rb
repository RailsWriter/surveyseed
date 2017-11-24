require 'csv'

begin
  timetorepeat = true
  count=0
  CSV.open('Reports/Dailycompletes', 'a') do |csv|
    #  csv << "Titles"
    User.where("updated_at > ?", (Time.now - 1440.minutes)).order( "updated_at").each do |m|
    # User.where("created_at > ?", (Time.now - 1440.minutes)).each do |m|
      if m.SurveysCompleted.nil? then
        # do nothing
      else
        @SurveysCompletedArray = m.SurveysCompleted.to_a
        if @SurveysCompletedArray.length > 0 then
          (0..@SurveysCompletedArray.length-1).each do |i|
            # print @SurveysCompletedArray[i][0]
            # puts
            # ********* Note this will not show Records when PID used be before Time stamp in the Records ************
            if (@SurveysCompletedArray[i][0].is_a?String) then
              # ignore - it is older storage format
            else
              if (@SurveysCompletedArray[i][0] > (Time.now - 1440.minutes)) then
                # print @SurveysCompletedArray[i][0]
                # puts
                # csv << @SurveysCompletedArray[i].flatten
                count=count+1
                print @SurveysCompletedArray[i].flatten
                puts
              else
              end
            end
          end
        else
        end
      end
    end
  end
  print "Number of completes in last 24 hrs: ", count
  puts
  print "UTC time ", Time.now
  puts
  # print "Local time ", Time.now-7*60*60 # Mar-Nov DST
  print "Local time ", Time.now-8*60*60 # Nov - Mar PST
  puts
  print "Going to sleep for 9 minutes"
  puts
  sleep (9.minutes)
end while timetorepeat