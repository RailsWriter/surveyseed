# This script updates old survey ranks to the new rankings.

Survey.all.each do |survey|
  
  if survey.GEPC == nil then
    survey.GEPC = 0.0
  else
  end
    

  survey.save
  print "Survey: ", survey.SurveyNumber
  puts
end