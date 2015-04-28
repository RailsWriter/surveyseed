require 'csv'

CSV.open('RFGcompletes', 'w') do |csv|
#  csv << "Titles"
  User.where("created_at > ?", (Time.now.midnight - 31.day)).each do |m|
    puts "user x"
    if m.SurveysCompleted.flatten(2).include?('RFG') == true then
      csv << m.SurveysCompleted.to_a.flatten
      puts "added a new row"
    else
    end
  end
end