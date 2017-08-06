require 'csv'

CSV.open('Reports/QuickRewardsCompletes', 'w') do |csv|
#  csv << "Titles"
  User.where("created_at > ?", (Time.now - 40.days)).each do |m|
    if m.SurveysCompleted.length > 0 then
      if m.SurveysCompleted.flatten(2).include?("QuickRewards") == true then
        csv << m.SurveysCompleted.to_a.flatten
        print m.SurveysCompleted
        puts
      else
      end
    else
    end
  end
end