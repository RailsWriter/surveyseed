# This script updates old survey ranks to the new rankings assuing them to be old and give Try More status unless GEPC=5.

Survey.all.each do |survey|
  
  
  if (500 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 600) then
    if survey.TCR > 0.05 then
      survey.SurveyGrossRank = survey.SurveyGrossRank - 400
      survey.save
      print "Moved and saved survey: ", survey.SurveyNumber
      puts
    else
    end
  end
  
  print "Survey: ", survey.SurveyNumber
  puts

end