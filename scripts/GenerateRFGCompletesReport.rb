require 'csv'

CSV.open('Reports/RFGcompletes', 'w') do |csv|
#  csv << "Titles"
  User.where("created_at > ?", (Time.now.midnight - 31.day)).each do |m|
    if m.SurveysCompleted.length > 0 then
      if m.SurveysCompleted.flatten(2).include?("RFG") == true then
        csv << m.SurveysCompleted.to_a.flatten
        print m.SurveysCompleted
        puts
      else
      end
    else
    end
  end
end