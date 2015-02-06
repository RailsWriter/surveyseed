# This script updates old survey ranks to the new rankings assuing them to be old and give Try More status unless GEPC=5.

Survey.all.each do |survey|

  # 201 is the highest rank for conversion =100. 300 is lowest rank for conversion=0

  if survey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
    p "Found a survey with Conversion = 0"
    survey.Conversion = 1
  else
  end
  survey.SurveyGrossRank = 201+(100-survey.Conversion)    
  
  # Assign all of them mid point KEPC for this rank range from 0.01 - 0.02
  survey.KEPC = 0.015
  
  # Initialize for future transition
  survey.FailureCount = 0
  survey.OverQuotaCount = 0  
  
  survey.save

end