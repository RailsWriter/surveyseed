# This script updates old survey ranks to the new rankings.

Survey.all.each do |survey|  
  
  #GEPC=5 -> Rank 301-400 to outside range 901-1000
  if (300 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 400) then  
    survey.SurveyGrossRank = survey.SurveyGrossRank + 600
    print "Ranked survey GEPC=5 to 901-1000: ", survey.SurveyNumber
    puts
  else
  end
  
  # TM -> From ranks 401-500 to 301-400
  if (400 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 500) then  
    survey.SurveyGrossRank = survey.SurveyGrossRank - 100
    print "Ranked survey TM to 301-400: ", survey.SurveyNumber
    puts
  else
  end

  survey.save
  print "Survey: ", survey.SurveyNumber
  puts
end

Survey.all.each do |survey|  

  # GEPC=5 -> Re-rank 901-1000 in to 401-500
  if (900 < survey.SurveyGrossRank) && (survey.SurveyGrossRank <= 1000) then  
    survey.SurveyGrossRank = survey.SurveyGrossRank - 500
    print "Ranked survey 901-1000 to 401-500: ", survey.SurveyNumber
    puts
  else
  end

  survey.save
  print "Survey: ", survey.SurveyNumber
  puts
end