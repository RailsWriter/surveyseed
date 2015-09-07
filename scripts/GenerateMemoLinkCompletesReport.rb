require 'csv'

CSV.open('Reports/MemoLinkcompletes', 'w') do |csv|
#  csv << "Titles"
  User.where("created_at > ?", (Time.now - 8.days)).each do |m|
    if m.SurveysCompleted.length > 0 then
      if m.SurveysCompleted.flatten(2).include?("MemoLink") == true then
        csv << m.SurveysCompleted.to_a.flatten
        print m.SurveysCompleted
        puts
      else
      end
    else
    end
  end
end