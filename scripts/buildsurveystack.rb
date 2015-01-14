# This script runs every few hrs (20 mins min) to get suitable surveys from Federated Sample Offerwall to Ketsci stack

require 'httparty'

# Set flag to 'prod' to use production and 'stag' for staging base URL

flag = 'prod'


@initialrankingapproach = 'ConversionsFirst' # set to 'EEPCFirst' or 'ConversionsFirst'


prod_base_url = "http://vpc-apiloadbalancer-991355604.us-east-1.elb.amazonaws.com"
staging_base_url = "http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com"

print "**************************** ENV is set to ", flag
puts
print "**************************** Ranking approach is set to: ", @initialrankingapproach
puts

if flag == 'prod' then
  base_url = prod_base_url
else
  if flag == 'stag' then
    base_url = staging_base_url
  else
    p "******** SET base URL correctly *******"
  end
end

print " ************* base url is", base_url
puts

# Get any new offerwall surveys from Federated Sample

begin
# set timer to download every 20 mins

  starttime = Time.now
  print 'BuildSurveyStack: Time at start', starttime
  puts
  
  begin
    sleep(1)
    puts 'CONNECTING FOR OFFERWALL SURVEYS LIST'
    
    if flag == 'prod' then
      offerwallresponse = HTTParty.get(base_url+'/Supply/v1/Surveys/AllOfferwall/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
    else
      if flag == 'stag' then
        offerwallresponse = HTTParty.get(base_url+'/Supply/v1/Surveys/AllOfferwall/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
      else
      end
    end
    
      rescue HTTParty::Error => e
        puts 'HttParty::Error '+ e.message
      retry
  end while offerwallresponse.code != 200

  puts 'http response', offerwallresponse
  totalavailablesurveys = offerwallresponse["ResultCount"] - 1
  print 'Total surveys', totalavailablesurveys+1
  puts
  
# **************** Remove the last few && about survey number - was a duplicate in staging
# With a $2.15 CPI from FED, a $1.50 max payout can be made

  (0..totalavailablesurveys).each do |i|
    
    if (Survey.where("SurveyNumber = ?", offerwallresponse["Surveys"][i]["SurveyNumber"])).exists? == false then
    
      if ((offerwallresponse["Surveys"][i]["CountryLanguageID"] == nil ) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 5) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 6) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 7) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 9)) && ((offerwallresponse["Surveys"][i]["StudyTypeID"] == nil ) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 1) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 11) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 13) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 14) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 15) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 16) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 17) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 19) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 21) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 23)) && ((offerwallresponse["Surveys"][i]["BidLengthOfInterview"] == nil ) || (offerwallresponse["Surveys"][i]["BidLengthOfInterview"] < 41)) && ((offerwallresponse["Surveys"][i]["CPI"] == nil) || (offerwallresponse["Surveys"][i]["CPI"] > 2.15)) && (offerwallresponse["Surveys"][i]["SurveyNumber"] != 67820) && (offerwallresponse["Surveys"][i]["SurveyNumber"] != 66091) && (offerwallresponse["Surveys"][i]["SurveyNumber"] != 65653) && (offerwallresponse["Surveys"][i]["SurveyNumber"] != 98319) && (offerwallresponse["Surveys"][i]["SurveyNumber"] != 101766) then

        # Save key offerwall data for each survey
    
        @survey = Survey.new
        @survey.SurveyName = offerwallresponse["Surveys"][i]["SurveyName"]
        @survey.SurveyNumber = offerwallresponse["Surveys"][i]["SurveyNumber"]
        @survey.SurveySID = offerwallresponse["Surveys"][i]["SurveySID"]
        @survey.StudyTypeID = offerwallresponse["Surveys"][i]["StudyTypeID"]
        @survey.CountryLanguageID = offerwallresponse["Surveys"][i]["CountryLanguageID"]
        @survey.BidIncidence = offerwallresponse["Surveys"][i]["BidIncidence"]
        @survey.LengthOfInterview = offerwallresponse["Surveys"][i]["LengthOfInterview"]
        @survey.BidLengthOfInterview = offerwallresponse["Surveys"][i]["BidLengthOfInterview"]
        @survey.CPI = offerwallresponse["Surveys"][i]["CPI"]
        @survey.Conversion = offerwallresponse["Surveys"][i]["Conversion"]
        @survey.TotalRemaining = offerwallresponse["Surveys"][i]["TotalRemaining"]
        @survey.OverallCompletes = offerwallresponse["Surveys"][i]["OverallCompletes"]
        @survey.SurveyMobileConversion = offerwallresponse["Surveys"][i]["SurveyMobileConversion"]
      

        # Code for testing
  
        SurveyName = offerwallresponse["Surveys"][i]["SurveyName"]
        SurveyNumber = offerwallresponse["Surveys"][i]["SurveyNumber"]
        print 'PROCESSING i =', i
        puts
        print 'SurveyName: ', SurveyName, ' SurveyNumber: ', SurveyNumber, ' CountryLanguageID: ', offerwallresponse["Surveys"][i]["CountryLanguageID"]
        puts
        
        

   
        # Assign an initial gross rank to the chosen survey
        # 10 is worst for the lowest conversion rate

        begin
          sleep(1)
          puts '**************************** CONNECTING FOR GLOBAL STATS on NEW survey: ', SurveyNumber
          if flag == 'prod' then
            SurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+SurveyNumber.to_s+'/5458/Global/Trailing?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
          else
            if flag == 'stag' then
              SurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+SurveyNumber.to_s+'/5411/Global/Trailing?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            else
            end
          end
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
        end while SurveyStatistics.code != 200
        
        
        # For the NEW survey - Store GEEPC in SurveyQuotaCalcTypeID as an integer. Also set SurveyExactRank and SampleTypeID to keep track of unsuccessful attempts and OQ instances respectively.
        
        @survey.SurveyExactRank = 0
        @survey.SampleTypeID = 0
        
        if SurveyStatistics["SurveyStatistics"]["EffectiveEPC"] > 0.2 then
          @survey.SurveyQuotaCalcTypeID = 1 # best kind
        else 
          if ((0 < SurveyStatistics["SurveyStatistics"]["EffectiveEPC"]) && (SurveyStatistics["SurveyStatistics"]["EffectiveEPC"] <= 0.2)) then
            @survey.SurveyQuotaCalcTypeID = 2 # second best kind
          else
            @survey.SurveyQuotaCalcTypeID = 5 # worst kind by GEEPC data
          end
        end
        
          
        
        if @initialrankingapproach == 'EEPCFirst' then
          if SurveyStatistics["SurveyStatistics"]["EffectiveEPC"] > 0.2 then
            @survey.SurveyGrossRank = 1
            print '*******************Effective GlobalEPC is > 0.2 = ', SurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
            puts
          else
            if ((0 < SurveyStatistics["SurveyStatistics"]["EffectiveEPC"]) && (SurveyStatistics["SurveyStatistics"]["EffectiveEPC"] <= 0.2)) then
              @survey.SurveyGrossRank = 5
              print '*******************Effective GlobalEPC is <= 0.2 = ', SurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
              puts
            else    
          
              case offerwallresponse["Surveys"][i]["Conversion"]
                when 0..5
                  puts "Lowest Rank 20"
                  @survey.SurveyGrossRank = 20
                when 6..10
                  puts "Rank 19"
                  @survey.SurveyGrossRank = 19
                when 11..15
                  puts "Rank 18"
                  @survey.SurveyGrossRank = 18
                when 16..20
                  puts "Rank 17"
                  @survey.SurveyGrossRank = 17
                when 21..25
                  puts "Rank 16"
                  @survey.SurveyGrossRank = 16
                when 26..30
                  puts "Rank 15"
                  @survey.SurveyGrossRank = 15
                when 31..35
                  puts "Rank 14"
                  @survey.SurveyGrossRank = 14
                when 36..40
                  puts "Rank 13"
                  @survey.SurveyGrossRank = 13
                when 41..45
                  puts "Rank 12"
                  @survey.SurveyGrossRank = 12
                when 46..50
                  puts "Rank 11"
                  @survey.SurveyGrossRank = 11
                when 51..55
                  puts "Rank 10"
                  @survey.SurveyGrossRank = 10
                when 56..60
                  puts "Rank 9"
                  @survey.SurveyGrossRank = 9
                when 61..65
                  puts "Rank 8"
                  @survey.SurveyGrossRank = 8
                when 66..70
                  puts "Rank 7"
                  @survey.SurveyGrossRank = 7
                when 71..75
                  puts "Rank 6"
                  @survey.SurveyGrossRank = 6
                when 76..80
                  puts "Rank 5"
                  @survey.SurveyGrossRank = 5
                when 81..85
                  puts "Rank 4"
                  @survey.SurveyGrossRank = 4
                when 86..90
                  puts "Rank 3"
                  @survey.SurveyGrossRank = 3
                when 91..95
                  puts "Rank 2"
                  @survey.SurveyGrossRank = 2
                when 96..100
                  puts "Highest Rank 1"
                  @survey.SurveyGrossRank = 1           
              end # end case
              
            end # end of if EEPC is between 0 and 0.2
          end # end of, if EEPC is more than 0.2
          
        else # for 'ConversionFirst' approach

          case offerwallresponse["Surveys"][i]["Conversion"]
          when 0..5
            puts "Lowest Rank 20"
            @survey.SurveyGrossRank = 20
          when 6..10
            puts "Rank 19"
            @survey.SurveyGrossRank = 19
          when 11..15
            puts "Rank 18"
            @survey.SurveyGrossRank = 18
          when 16..20
            puts "Rank 17"
            @survey.SurveyGrossRank = 17
          when 21..25
            puts "Rank 16"
            @survey.SurveyGrossRank = 16
          when 26..30
            puts "Rank 15"
            @survey.SurveyGrossRank = 15
          when 31..35
            puts "Rank 14"
            @survey.SurveyGrossRank = 14
          when 36..40
            puts "Rank 13"
            @survey.SurveyGrossRank = 13
          when 41..45
            puts "Rank 12"
            @survey.SurveyGrossRank = 12
          when 46..50
            puts "Rank 11"
            @survey.SurveyGrossRank = 11
          when 51..55
            puts "Rank 10"
            @survey.SurveyGrossRank = 10
          when 56..60
            puts "Rank 9"
            @survey.SurveyGrossRank = 9
          when 61..65
            puts "Rank 8"
            @survey.SurveyGrossRank = 8
          when 66..70
            puts "Rank 7"
            @survey.SurveyGrossRank = 7
          when 71..75
            puts "Rank 6"
            @survey.SurveyGrossRank = 6
          when 76..80
            puts "Rank 5"
            @survey.SurveyGrossRank = 5
          when 81..85
            puts "Rank 4"
            @survey.SurveyGrossRank = 4
          when 86..90
            puts "Rank 3"
            @survey.SurveyGrossRank = 3
          when 91..95
            puts "Rank 2"
            @survey.SurveyGrossRank = 2
          when 96..100
            puts "Highest Rank 1"
            @survey.SurveyGrossRank = 1 
          end # end of case            
          
        end # end of rankingapproach switch

          # Get Survey Qualifications Information by SurveyNumber
          begin
            sleep(1)
            puts 'CONNECTING FOR QUALIFICATIONS INFORMATION'
 
          if flag == 'prod' then
            SurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
          else
            if flag == 'stag' then
              SurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            else
            end
          end
 
#         SurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
          end while SurveyQualifications.code != 200

          # By default all users are qualified
    
          @survey.QualificationAgePreCodes = ["ALL"]
          @survey.QualificationGenderPreCodes = ["ALL"]
          @survey.QualificationZIPPreCodes = ["ALL"]          
          @survey.QualificationRacePreCodes = ["ALL"]
          @survey.QualificationEthnicityPreCodes = ["ALL"]  
          @survey.QualificationEducationPreCodes = ["ALL"]  
          @survey.QualificationHHIPreCodes = ["ALL"]
          

          # Insert specific qualifications where required

          if SurveyQualifications["SurveyQualification"]["Questions"] == nil then
#          if SurveyQualifications["SurveyQualification"]["Questions"].empty? then
            puts '******************** SurveyQualifications or Questions is NIL'
            @survey.QualificationAgePreCodes = ["ALL"]
            @survey.QualificationGenderPreCodes = ["ALL"]
            @survey.QualificationZIPPreCodes = ["ALL"]            
            @survey.QualificationRacePreCodes = ["ALL"]
            @survey.QualificationEthnicityPreCodes = ["ALL"]  
            @survey.QualificationEducationPreCodes = ["ALL"]  
            @survey.QualificationHHIPreCodes = ["ALL"]  
            
            
          else
            NumberOfQualificationsQuestions = SurveyQualifications["SurveyQualification"]["Questions"].length-1
            print 'NumberOfQualificationsQuestions: ', NumberOfQualificationsQuestions+1
            puts
    
            (0..NumberOfQualificationsQuestions).each do |j|
              # Survey.Questions = SurveyQualifications["SurveyQualification"]["Questions"]
 #             puts SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
              case SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
                when 42
                  if flag == 'stag' then
                    print 'AGE: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @survey.QualificationAgePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 43
                  print 'GENDER: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  puts
                  @survey.QualificationGenderPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 45
                  if flag == 'stag' then
                    print 'ZIP: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 47
                  if flag == 'stag' then
                    print 'HISPANIC->Ethnicity: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  # Note: FED calls our Ethnicity definition as HISPANIC. Adhering to our definition.
                  @survey.QualificationEthnicityPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 113
                  if flag == 'stag' then
                    print 'ETHNICITY->Race: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  # Note: FED calls our Race definition as ETNICITY. Adhering to our definition.
                  @survey.QualificationRacePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 633
                  if flag == 'stag' then
                    print 'STANDARD_EDUCATION: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @survey.QualificationEducationPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 14785
                  if flag == 'stag' then
                    print 'STANDARD_HHI_US: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @survey.QualificationHHIPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")  
                when 14887
                  if flag == 'stag' then
                    print 'STANDARD_HHI_INT: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @survey.QualificationHHIPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")                  
              end # case
              
            end #do      
          end # if
    
          # Get Survey Quotas Information by SurveyNumber
          begin
            sleep(1)
            puts 'CONNECTING FOR QUOTA INFORMATION'
          
            if flag == 'prod' then
              @SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                @SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
          
#           @SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
            end while @SurveyQuotas.code != 200

            # Save quotas information for each survey

#            if @SurveyQuotas["SurveyStillLive"] == false then
#              @survey.delete
#            else
              @survey.SurveyStillLive = @SurveyQuotas["SurveyStillLive"]
              @survey.SurveyStatusCode = @SurveyQuotas["SurveyStatusCode"]
              @survey.SurveyQuotas = @SurveyQuotas["SurveyQuotas"]
#            end
        
            # Get Supplierlinks for the survey
    
            begin
              sleep(1)
              print 'POSTING WITH REDIRECTS AND TO GET LIVELINK AS SURVEYLINK for SurveyNumber = ', SurveyNumber
              puts
       
              if flag == 'stag' then
                SupplierLink = HTTParty.post(base_url+'/Supply/v1/SupplierLinks/Create/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E',
                :body => { :SupplierLinkTypeCode => "OWS", 
                  :TrackingTypeCode => "NONE", 
                  :DefaultLink => "https://www.ketsci.com/redirects/status?status=1&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]",
        	        :SuccessLink => "https://www.ketsci.com/redirects/status?status=2&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]&cost=[%COST%]",
        	        :FailureLink => "https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]",
        	        :OverQuotaLink => "https://www.ketsci.com/redirects/status?status=4&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]",
        	        :QualityTerminationLink => "https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]"
                }.to_json,
                :headers => { 'Content-Type' => 'application/json' })
              else
                if flag == 'prod' then
                  SupplierLink = HTTParty.post(base_url+'/Supply/v1/SupplierLinks/Create/'+SurveyNumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702',
                  :body => { :SupplierLinkTypeCode => "OWS", 
                    :TrackingTypeCode => "NONE"
                  }.to_json,
                  :headers => { 'Content-Type' => 'application/json' })
                else
              end
            end

            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
            end while SupplierLink.code != 200

            print '******************* SUPPLIERLINKS ARE AVAILABLE: ', SupplierLink["SupplierLink"]
            puts
#            puts SupplierLink["SupplierLink"]["LiveLink"]
            @survey.SupplierLink=SupplierLink["SupplierLink"]   
            @survey.CPI = SupplierLink["SupplierLink"]["CPI"]  
    
            # Finally save the survey information in the database
            print '**************************************************** SAVING THE SURVEYLINKS IN DATABASE'
            puts
            @survey.save
          else
            print 'This survey does not meet the CountryLanguageID, SurveyType, or Bid InterviewLength criteria.'
            print 'At end i =', i, ' SurveyNumber = ', offerwallresponse["Surveys"][i]["SurveyNumber"]
            puts
      
#      if flag == 'stag' then
#      ans1 = ((offerwallresponse["Surveys"][i]["CountryLanguageID"] == nil ) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 6) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 7) ||          (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 9))
#      ans2 = ((offerwallresponse["Surveys"][i]["StudyTypeID"] == nil ) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 1) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 8) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 9) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 10) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 11) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 12) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 13) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 14) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 15) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 16) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 21) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 23))
 #     ans3 = ((offerwallresponse["Surveys"][i]["BidIncidence"] == nil ) || (offerwallresponse["Surveys"][i]["BidIncidence"] > 10 ))
#      ans4 = ((offerwallresponse["Surveys"][i]["BidLengthOfInterview"] == nil ) || (offerwallresponse["Surveys"][i]["BidLengthOfInterview"] < 41))
 #     puts 'Ans1', ans1, 'Ans2', ans2, 'Ans3', ans3, 'Ans4', ans4
 #     else
#      end
     
          #End of second if. Going through all (i)
        end
      else
        # End of first if. This (i) survey is already in the database => nothing to do. Update script will take care of quota changes and removal.
        # BUT this should never happen because once SupplierLink is created the survey is moved from OW to Allocation List
        print 'This survey is already in database:', offerwallresponse["Surveys"][i]["SurveyNumber"]
        puts
      end
      # End of totalavailablesurveys (do loop)
    end

      timenow = Time.now
  
      print 'BuildSurveyStack: Time at end', timenow
      puts
      if (timenow - starttime) > 1200 then 
        print 'time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
        puts
        timetorepeat = true
      else
        print 'time elapsed since start =', (timenow - starttime), '- going to sleep for 20 minutes since it typically takes under 10 mins to do a sweep'
        puts
        sleep (20.minutes)
#    sleep (1200 - (timenow - starttime))
        timetorepeat = true
      end

    end while timetorepeat