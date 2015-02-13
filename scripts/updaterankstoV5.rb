# This script updates old survey ranks to the new rankings assuing them to be old and give Try More status unless GEPC=5.

Survey.all.each do |survey|
  
  if (200 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 300) then  
    survey.SurveyGrossRank = survey.SurveyGrossRank + 600
  else
  end
  
  
  if (100 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 200) || 
    (400 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 500) ||
    (500 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 600) then
      survey.SurveyGrossRank = survey.SurveyGrossRank + 100
  else
  end
  
  
  if (0 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 100) then
      survey.SurveyGrossRank = survey.SurveyGrossRank + 500
    end
    
    if (800 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 900) then
        survey.SurveyGrossRank = survey.SurveyGrossRank - 400
      end
  
  
  # Assign all surveys

  survey.NumberofAttemptsAtLastComplete = survey.SurveyExactRank # starting point from where the count is currently
  
  if survey.CompletedBy.length > 0 then
    survey.TCR = ((survey.CompletedBy.length).to_f / (survey.SurveyExactRank + survey.CompletedBy.length)).round(3)
  else
    survey.TCR = 0.0
  end
  
  survey.save
  print "Saved survey: ", survey.SurveyNumber
  puts
end