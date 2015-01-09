# This script updates old survey ranks to the new rankings

Survey.all.each do |survey|
	case survey.Conversion
          when 0..5
            puts "Lowest Rank 20"
            survey.SurveyGrossRank = 20
          when 6..10
            puts "Rank 19"
            survey.SurveyGrossRank = 19
          when 11..15
            puts "Rank 18"
            survey.SurveyGrossRank = 18
          when 16..20
            puts "Rank 17"
            survey.SurveyGrossRank = 17
          when 21..25
            puts "Rank 16"
            survey.SurveyGrossRank = 16
          when 26..30
            puts "Rank 15"
            survey.SurveyGrossRank = 15
          when 31..35
            puts "Rank 14"
            survey.SurveyGrossRank = 14
          when 36..40
            puts "Rank 13"
            survey.SurveyGrossRank = 13
          when 41..45
            puts "Rank 12"
            survey.SurveyGrossRank = 12
          when 46..50
            puts "Rank 11"
            survey.SurveyGrossRank = 11
          when 51..55
            puts "Rank 10"
            survey.SurveyGrossRank = 10
          when 56..60
            puts "Rank 9"
            survey.SurveyGrossRank = 9
          when 61..65
            puts "Rank 8"
            survey.SurveyGrossRank = 8
          when 66..70
            puts "Rank 7"
            survey.SurveyGrossRank = 7
          when 71..75
            puts "Rank 6"
            survey.SurveyGrossRank = 6
          when 76..80
            puts "Rank 5"
            survey.SurveyGrossRank = 5
          when 81..85
            puts "Rank 4"
            survey.SurveyGrossRank = 4
          when 86..90
            puts "Rank 3"
            survey.SurveyGrossRank = 3
          when 91..95
            puts "Rank 2"
            survey.SurveyGrossRank = 2
          when 96..100
            puts "Highest Rank 1"
            survey.SurveyGrossRank = 1
		end # case
    survey.SurveyQuotaCalcTypeID = 2 # initialize it for GEEPC to be not nil for pre-existing surveys and reduce rank by a small amount in case of too many incompletes
    survey.SurveyExactRank = 0 # initialize surveyExactRank (i.e. unsuccessful attempts) to be not nil when used with previously downloaded surveys
    survey.SampleTypeID = 0 # initialize to make existing surveys have an initial 0 value for OQ instead of nil
    survey.save
end