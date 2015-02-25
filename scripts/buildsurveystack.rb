# This script runs every 20 mins to get index of surveys from Federated Sample Offerwall

require 'httparty'

# Set flag to 'prod' to use production and 'stag' for staging base URL


flag = 'prod'


prod_base_url = "http://vpc-apiloadbalancer-991355604.us-east-1.elb.amazonaws.com"
staging_base_url = "http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com"

print "**************************** ENV is set to ", flag
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


# Get any new offerwall surveys from Federated Sample

begin
# set timer to download every 20 mins

  starttime = Time.now
  print '************************************** BuildSurveyStack: Time at start', starttime
  puts
  
  begin
    sleep(1)
    puts '*************** CONNECTING TO OFFERWALL for ALL SURVEYS LIST'
    
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
  print '************* Total surveys: ', totalavailablesurveys+1
  puts
  
  
# With a $2.15 CPI from FED, a $1.50 max payout can be made.
# Consider removing the CPI condition from builder and updater and only keep it in the user controller.

  (0..totalavailablesurveys).each do |i|
    
    if (Survey.where("SurveyNumber = ?", offerwallresponse["Surveys"][i]["SurveyNumber"])).exists? == false then
    
      if ((offerwallresponse["Surveys"][i]["CountryLanguageID"] == nil ) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 5) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 6) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 7) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 9)) && ((offerwallresponse["Surveys"][i]["StudyTypeID"] == nil ) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 1) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 11) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 13) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 14) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 15) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 16) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 17) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 19) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 21) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 23)) && ((offerwallresponse["Surveys"][i]["CPI"] == nil) || (offerwallresponse["Surveys"][i]["CPI"] > 0.99)) then

        # Save key data for the NEW survey i
    
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
        
        # For the NEW survey - store GEPC. Also set SurveyExactRank, etc. to keep track of F/OQ/S instances.
        
        @survey.FailureCount = 0
        @survey.OverQuotaCount = 0
        @survey.KEPC = 0.0
        @survey.NumberofAttemptsAtLastComplete = 0
        @survey.TCR = 0.0
        @survey.SurveyExactRank = 0
  
        SurveyName = offerwallresponse["Surveys"][i]["SurveyName"]
        SurveyNumber = offerwallresponse["Surveys"][i]["SurveyNumber"]
        
  
        print '********************************************* PROCESSING i =', i
        puts
        print '************************ SurveyName: ', SurveyName, ' SurveyNumber: ', SurveyNumber, ' CountryLanguageID: ', offerwallresponse["Surveys"][i]["CountryLanguageID"]
        puts
        
   
        # Assign an initial ranks to the chosen new survey by its Conv or GCR (GEPC/CPI), if Conv=0. New surveys with Conv>0 are put in 201-300 and Conv=0 are in 401-500.
        

        begin
          sleep(1)
          print '**************************** CONNECTING FOR GLOBAL STATS (GEPC) on NEW survey: ', SurveyNumber
          puts
          
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
        
        
        if SurveyStatistics["SurveyStatistics"]["EffectiveEPC"] != nil then
          @survey.GEPC = SurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
        else
          @survey.GEPC = 0.0
        end

        
        # Convert GEPC to GCR to give priority to CR over EPC.
        if @survey.CPI >0 then
          @GCR = @survey.GEPC / @survey.CPI
        else
          @GCR = @survey.GEPC
        end
        
        
        if @survey.Conversion > 0 then
          
            @survey.SurveyGrossRank = 201+(100-@survey.Conversion)
            print "Assigned Conv>0 survey rank: ", @survey.SurveyGrossRank
            puts
        
        else # Conv=0
        
          if (@GCR >= 1) then
            @survey.SurveyGrossRank = 401
            print "Assigned Conv=0 survey rank: ", @survey.SurveyGrossRank, "GCR= ", @GCR
            puts
             
          else
            
            @survey.SurveyGrossRank = 500-(100*@GCR)
            print "Assigned Conv=0 survey rank: ", @survey.SurveyGrossRank, "GCR= ", @GCR
            puts
          end

        end          
                    

          # Get Survey Qualifications Information by SurveyNumber
          begin
            sleep(1)
            puts '****************************** CONNECTING FOR QUALIFICATIONS INFORMATION'
 
          if flag == 'prod' then
            SurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
          else
            if flag == 'stag' then
              SurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            else
            end
          end
 
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
          end while SurveyQualifications.code != 200


          # By default all users are qualified
          
          
          # ********************* Change HHC to Employment
          
    
          @survey.QualificationAgePreCodes = ["ALL"]
          @survey.QualificationGenderPreCodes = ["ALL"]
          @survey.QualificationZIPPreCodes = ["ALL"]          
          @survey.QualificationRacePreCodes = ["ALL"]
          @survey.QualificationEthnicityPreCodes = ["ALL"]  
          @survey.QualificationEducationPreCodes = ["ALL"]  
          @survey.QualificationHHIPreCodes = ["ALL"]
          @survey.QualificationHHCPreCodes = ["ALL"]
          

        # Insert specific qualifications where required
          

          if SurveyQualifications["SurveyQualification"]["Questions"] == nil then
            
            puts '******************** SurveyQualifications Question is NIL'
            
            @survey.QualificationAgePreCodes = ["ALL"]
            @survey.QualificationGenderPreCodes = ["ALL"]
            @survey.QualificationZIPPreCodes = ["ALL"]            
            @survey.QualificationRacePreCodes = ["ALL"]
            @survey.QualificationEthnicityPreCodes = ["ALL"]  
            @survey.QualificationEducationPreCodes = ["ALL"]  
            @survey.QualificationHHIPreCodes = ["ALL"]
            @survey.QualificationHHCPreCodes = ["ALL"]
            
            
          else
            NumberOfQualificationsQuestions = SurveyQualifications["SurveyQualification"]["Questions"].length-1
            print '*********************** NumberOfQualificationsQuestions: ', NumberOfQualificationsQuestions+1
            puts
    
            (0..NumberOfQualificationsQuestions).each do |j|

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
                  if flag == 'stag' then
                    print 'GENDER: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
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
                when 7064
                  if flag == 'stag' then
                    print '------------------------------------------------------------------->> Parental_Status_Standard: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                when 1249
                  if flag == 'stag' then
                    print '----------------------------------------------------------------->> Age_and_Gender_of_Child: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  
                  
                when 2189
                  if flag == 'stag' then
                    print '------------------------------------------------------------>> STANDARD_EMPLOYMENT: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  p '------------------------------------------------------------>> Rename HHComp to STANDARD_EMPLOYMENT: '
                  @survey.QualificationHHCPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")  
             
             
             
                when 643
                  if flag == 'stag' then
                    print '------------------------------------------------------------->> STANDARD_INDUSTRY: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end    
              end # case
              
            end #do      
          end # if
    
        
          
        # Get Survey Quotas Information by SurveyNumber
          
          begin
            sleep(1)
            puts '************************************ CONNECTING FOR QUOTA INFORMATION'
          
            if flag == 'prod' then
              @SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                @SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
          
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
            end while @SurveyQuotas.code != 200

            # Save quotas information for each survey

              @survey.SurveyStillLive = @SurveyQuotas["SurveyStillLive"]
              @survey.SurveyStatusCode = @SurveyQuotas["SurveyStatusCode"]
              @survey.SurveyQuotas = @SurveyQuotas["SurveyQuotas"]
              
        
          # Get Supplierlinks for the survey
    
            begin
              sleep(1)
              print '********************** GET SUPPLIERLINKS for SurveyNumber = ', SurveyNumber
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

            print '******************* SUPPLIERLINKS ARE AVAILABLE for the NEW Survey: ', SupplierLink["SupplierLink"]
            puts
#            puts SupplierLink["SupplierLink"]["LiveLink"]
            @survey.SupplierLink=SupplierLink["SupplierLink"]   
            @survey.CPI = SupplierLink["SupplierLink"]["CPI"]  
    
            # Finally save the survey information in the database
            print '**************************************************** SAVING THE SURVEYLINKS and all other SURVEY DATA IN DATABASE'
            puts
            @survey.save
          else
            print 'This survey does not meet the CountryLanguageID, SurveyType, or CPI criteria.'
            print 'At end i =', i, ' SurveyNumber = ', offerwallresponse["Surveys"][i]["SurveyNumber"]
            puts
      
     
          #End of second if. Going through all (i)
      end
    else
      # End of first if. This (i) survey is already in the database => nothing to do. Update script will take care of quota changes and removal.
      # BUT this should never happen because once SupplierLink is created the survey is moved from OW to Allocation List
      print '************************This survey is already in database:', offerwallresponse["Surveys"][i]["SurveyNumber"]
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
        timetorepeat = true
      end

end while timetorepeat