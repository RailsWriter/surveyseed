require 'csv'

CSV.open('MemoLinkcompletes', 'w') do |csv|
#  csv << "Titles"
  User.where("created_at > ?", (Time.now.midnight - 7.day)).each do |m|
    print "created_at", m.created_at
    print "m.SurveysCompleted: ", m.SurveysCompleted
    print "m.SurveysCompleted.length: ", m.SurveysCompleted.length
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