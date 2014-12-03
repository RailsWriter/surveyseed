# This script runs every few hrs (15 mins min) to get suitable surveys from Federated Sample Offerwall to Ketsci stack

require 'httparty'

# set timer to download every 20 mins

begin
  starttime = Time.now

  # Get any new offerwall surveys from Federated Sample

  begin
    sleep(4)
    puts 'CONNECTING FOR OFFERWALL SURVEYS LIST'
    offerwallresponse = HTTParty.get("http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/Surveys/AllOfferwall/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E")
      rescue HTTParty::Error => e
        puts 'HttParty::Error '+ e.message
      retry
  end while offerwallresponse.code != 200

  puts offerwallresponse
  totalavailablesurveys = offerwallresponse["ResultCount"] - 1
  puts totalavailablesurveys+1

  (0..totalavailablesurveys).each do |i|
    if ((offerwallresponse["Surveys"][i]["CountryLanguageID"] == nil ) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 6) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 7) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 9)) && ((offerwallresponse["Surveys"][i]["StudyTypeID"] == nil ) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 1) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 8) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 9) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 10) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 11) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 12) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 13) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 14) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 15) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 16) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 21) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 23)) && ((offerwallresponse["Surveys"][i]["BidIncidence"] == nil ) || (offerwallresponse["Surveys"][i]["BidIncidence"] > 10 )) && ((offerwallresponse["Surveys"][i]["BidLengthOfInterview"] == nil ) || (offerwallresponse["Surveys"][i]["BidLengthOfInterview"] < 41)) then

      # Save key offerwall data for each survey
    
      @survey = Survey.new
      @survey.SurveyName = offerwallresponse["Surveys"][i]["SurveyName"]
      @survey.SurveyNumber = offerwallresponse["Surveys"][i]["SurveyNumber"]
      @survey.StudyTypeID = offerwallresponse["Surveys"][i]["StudyTypeID"]
      @survey.CountryLanguageID = offerwallresponse["Surveys"][i]["CountryLanguageID"]
      @survey.BidIncidence = offerwallresponse["Surveys"][i]["BidIncidence"]
      @survey.BidLengthOfInterview = offerwallresponse["Surveys"][i]["BidLengthOfInterview"]
   
      # Assign an initial gross rank to the chosen survey
    
      case offerwallresponse["Surveys"][i]["Conversion"]
        when 0..4
          puts "Rank 1"
          @survey.SurveyGrossRank = 1
        when 5..9
          puts "Rank 2"
          @survey.SurveyGrossRank = 2
        when 10..14
          puts "Rank 3"
          @survey.SurveyGrossRank = 3
        when 15..19
          puts "Rank 4"
          @survey.SurveyGrossRank = 4
        when 20..24
          puts "Rank 5"
          @survey.SurveyGrossRank = 5
        when 25..29
          puts "Rank 6"
          @survey.SurveyGrossRank = 6
        when 30..34
          puts "Rank 7"
          @survey.SurveyGrossRank = 7
        when 35..39
          puts "Rank 8"
          @survey.SurveyGrossRank = 8
        when 40..44
          puts "Rank 9"
          @survey.SurveyGrossRank = 9
        when 45..100
          puts "Rank 10"
          @survey.SurveyGrossRank = 10
        end

        # Code for testing
    
	      SurveyName = offerwallresponse["Surveys"][i]["SurveyName"]
	      SurveyNumber = offerwallresponse["Surveys"][i]["SurveyNumber"]
        puts 'PROCESSING i =', i
	      puts SurveyName, SurveyNumber, offerwallresponse["Surveys"][i]["CountryLanguageID"]

        # Get Survey Qualifications Information by SurveyNumber
    
      begin
        sleep(4)
        puts 'CONNECTING FOR QUALIFICATIONS INFORMATION'
        SurveyQualifications = HTTParty.get('http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
          rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
          retry
        end while SurveyQualifications.code != 200

        # By default all users are qualified
    
        @survey.QualificationAgePreCodes = ["ALL"]
        @survey.QualificationGenderPreCodes = ["ALL"]
        @survey.QualificationZIPPreCodes = ["ALL"] 

        # Insert specific qualifications where required

        if SurveyQualifications["SurveyQualification"]["Questions"] == nil then
          puts 'SurveyQualifications or Questions is NIL'
          @survey.QualificationAgePreCodes = ["ALL"]
          @survey.QualificationGenderPreCodes = ["ALL"]
          @survey.QualificationZIPPreCodes = ["ALL"]  
        else
          NumberOfQualificationsQuestions = SurveyQualifications["SurveyQualification"]["Questions"].length-1
          puts NumberOfQualificationsQuestions+1
    
          (0..NumberOfQualificationsQuestions).each do |j|
            # Survey.Questions = SurveyQualifications["SurveyQualification"]["Questions"]
            puts SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
        
            case SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
              when 42
                puts '42:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                @survey.QualificationAgePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              when 43
                puts '43:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                @survey.QualificationGenderPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              when 45
                puts '45:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                @survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            end
          end      
        end
    
        # Get Survey Quotas Information by SurveyNumber
        begin
          sleep(4)
          puts 'CONNECTING FOR QUOTA INFORMATION'
          SurveyQuotas = HTTParty.get('http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
            retry
        end while SurveyQuotas.code != 200

        # Save quotas information for each survey
    
        @survey.SurveyStillLive = SurveyQuotas["SurveyStillLive"]
        @survey.SurveyStatusCode = SurveyQuotas["SurveyStatusCode"]
        @survey.SurveyQuotas = SurveyQuotas["SurveyQuotas"]
        
        # Get Supplierlinks for the survey
    
      begin
        sleep(4)
        puts 'POSTING TO GET SURVEYLINK'
        SupplierLink = HTTParty.post('http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/SupplierLinks/Create/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E',
        :body => { :SupplierLinkTypeCode => "OWS", :TrackingTypeCode => "S2S" }.to_json,
        :headers => { 'Content-Type' => 'application/json' })
        rescue HTTParty::Error => e
          puts 'HttParty::Error '+ e.message
        retry
      end while SupplierLink.code != 200

      puts SupplierLink["SupplierLink"]
      puts SupplierLink["SupplierLink"]["LiveLink"]
      @survey.SupplierLink=SupplierLink["SupplierLink"]   
    
      # Finally save the survey information in the database
      @survey.save
    
    else
      # This survey does not meet the CountryLanguageID, SurveyType, BidIncidence, Bid InterviewLength criteria
    end
    # End of totalavailablesurveys
  end

  timenow = Time.now

  if (timenow - starttime) > 1200 then 
    puts 'time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
    timetorepeat = true
  else
    puts 'time elapsed since start =', (timenow - starttime), '- going to sleep for', (1200 - (timenow - starttime)), 'seconds'
    sleep (1200 - (timenow - starttime))
    timetorepeat = true
  end

end while timetorepeat