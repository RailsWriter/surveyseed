require 'csv'

CSV.open('Reports/QuickRewardsCompletesNew', 'a') do |csv|
  csv << ["Time of Complete (UTC)", "Ketsci PID", "Survey Number", "Supply Source", "CPA", "QuickRewards CID", "Network Name"]
  User.where("updated_at > ?", (Time.now - 45.days)).each do |m|
    if m.SurveysCompleted.nil? then
      # do nothing
    else
      @SurveysCompletedArray = m.SurveysCompleted.to_a
      if @SurveysCompletedArray.length > 0 then
        (0..@SurveysCompletedArray.length-1).each do |i|
          # ********* Note this will not show Records when PID used be before Time stamp in the Records ************
          if (@SurveysCompletedArray[i][0].is_a?String) then
            # ignore - it is older storage format
          else
            if ((@SurveysCompletedArray[i][0] > (Time.now - 45.days)) && (@SurveysCompletedArray[i].flatten.include?("QuickRewards"))) then
              csv << @SurveysCompletedArray[i].flatten
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