require 'csv'

CSV.open('Reports/MemoLinkcompletes', 'w') do |csv|
#  csv << "Titles"
  User.where("created_at > ?", (Time.now - 7.days)).each do |m|
    print "m.SurveysCompleted: ", m.SurveysCompleted
    puts
    if m.SurveysCompleted.length > 0 then
      if m.SurveysCompleted.flatten(2).include?("MemoLink") == true then
        csv << m.SurveysCompleted.to_a.flatten
        puts "added a new row"
      else
      end
    else
    end
  end
end