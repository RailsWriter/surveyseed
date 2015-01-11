require 'httparty'

# Set flag to 'prod' to use production and 'stag' for staging base URL

flag = 'prod'

@updatesrankingapproach = 'ConversionsFirst' # set to 'EEPCFirst' or 'ConversionsFirst'


prod_base_url = "http://vpc-apiloadbalancer-991355604.us-east-1.elb.amazonaws.com"
staging_base_url = "http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com"

print "**************************** QUOTA UPDATE: ENV is set to ", flag
puts

if flag == 'prod' then
  base_url = prod_base_url
else
  if flag == 'stag' then
    base_url = staging_base_url
  else
    p "******** QUOTA UPDATE: SET base URL correctly *******"
  end
end

print " ************* QUOTA UPDATE: base url is", base_url
puts



# Download the full allocations index

begin

  starttime = Time.now
  print 'At start at', starttime
  puts
  
  begin
    sleep(1)
    puts 'CONNECTING FOR index of ALLOCATED SURVEYS' 
 
    if flag == 'prod' then
     IndexofAllocatedSurveys = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/All/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
    else
     if flag == 'stag' then
       IndexofAllocatedSurveys = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/All/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
     else
     end
    end
 
    rescue HTTParty::Error => e
      puts 'HttParty::Error '+ e.message
      retry
  end while IndexofAllocatedSurveys.code != 200

  print 'http response', IndexofAllocatedSurveys
  puts
  totalavailablesurveys = IndexofAllocatedSurveys["ResultCount"] - 1
  print 'Total allocated surveys', totalavailablesurveys+1
  puts


  # Check if any survey has allocation remaining, current qualifications, quota remaining and current quota.


  (0..totalavailablesurveys).each do |i|
    @surveynumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
    if (Survey.where("SurveyNumber = ?", @surveynumber)).exists? then 
      Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey|

        # Check if this exisitng survey has any remaining total allocation on the offerwall.

        begin
          sleep(1)
          print '**************************** CONNECTING FOR SUPPLIER ALLOCATIONS INFORMATION of an EXISTING survey: ', @surveynumber
          puts
          
          if flag == 'prod' then
            @SupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+@surveynumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
          else
            if flag == 'stag' then
              @SupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+@surveynumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            else
            end
          end
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
        end while @SupplierAllocations.code != 200
        
        

        if @SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"] > 0 then
          
          print "********************* There is total remaining allocation for this EXISTING survey number: ", @surveynumber, ' in the amount of: ', @SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]
          puts


          # Update the rank of the survey if Conversion value has changed since originally downloaded. However, make no change if own data exists i.e. we have seen 20 or more responsdents fail the survey or we have recorded one or more completes and raised the rank to 1.
          
          survey.Conversion = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
          
          if (survey.SurveyExactRank > 20) || (survey.CompletedBy.length > 0) then # if 20
            # do nothing
          else # If 20
            # update Rank with new Conversion data
            case IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
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
            end # end case
          end # if 20

      begin
        sleep(1)
        print 'CONNECTING FOR QUALIFICATIONS INFORMATION on existing survey: ', @surveynumber
        puts
        
        if flag == 'prod' then
          SurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+@surveynumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
        else
          if flag == 'stag' then
            SurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+@surveynumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
          else
          end
        end
          rescue HTTParty::Error => e
          puts 'HttParty::Error '+ e.message
          retry
      end while SurveyQualifications.code != 200
          

      # By default all users are qualified

      survey.QualificationAgePreCodes = ["ALL"]
      survey.QualificationGenderPreCodes = ["ALL"]
      survey.QualificationZIPPreCodes = ["ALL"]      
      survey.QualificationRacePreCodes = ["ALL"]
      survey.QualificationEthnicityPreCodes = ["ALL"]  
      survey.QualificationEducationPreCodes = ["ALL"]  
      survey.QualificationHHIPreCodes = ["ALL"]


      # Update specific qualifications to be current information

      if SurveyQualifications["SurveyQualification"]["Questions"] == nil then
#      if SurveyQualifications["SurveyQualification"]["Questions"].empty? then
        puts 'SurveyQualifications or Questions is NIL'
        survey.QualificationAgePreCodes = ["ALL"]
        survey.QualificationGenderPreCodes = ["ALL"]
        survey.QualificationZIPPreCodes = ["ALL"]    
        survey.QualificationRacePreCodes = ["ALL"]
        survey.QualificationEthnicityPreCodes = ["ALL"]  
        survey.QualificationEducationPreCodes = ["ALL"]  
        survey.QualificationHHIPreCodes = ["ALL"]  
       
      else
        @NumberOfQualificationsQuestions = SurveyQualifications["SurveyQualification"]["Questions"].length-1
        print '************** @NumberOfQualificationsQuestions: ', @NumberOfQualificationsQuestions+1
        puts
            
        (0..@NumberOfQualificationsQuestions).each do |j|
          # Survey.Questions = SurveyQualifications["SurveyQualification"]["Questions"]
 #        puts SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
        
          case SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
            when 42
              if flag == 'stag' then
                print 'AGE: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationAgePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 43
              print 'GENDER: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              puts
              survey.QualificationGenderPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 45
              if flag == 'stag' then
#                print 'ZIP:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
#                puts
              else
              end
              survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 47
              if flag == 'stag' then
                print 'HISPANIC->Ethnicity: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              # Note: FED calls our Ethnicity definition as HISPANIC. Adhering to our definition.
              survey.QualificationEthnicityPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 113
              if flag == 'stag' then
                print 'ETHNICITY->Race: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              # Note: FED calls our Race definition as ETHNICITY. Adhering to our definition.
              survey.QualificationRacePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 633
              if flag == 'stag' then
                print 'STANDARD_EDUCATION: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationEducationPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 14785
              if flag == 'stag' then
                print 'STANDARD_HHI_US: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationHHIPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")  
            when 14887
              if flag == 'stag' then
                print 'STANDARD_HHI_INT: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationHHIPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")               
          end # case
          
        end #do j     
      end # if on Questions
 
 
      # Update Survey Quotas Information by SurveyNumber to current information
      begin
        sleep(1)
        print 'CONNECTING FOR QUOTA INFORMATION on existing survey: ', @surveynumber
        puts
          
        if flag == 'prod' then
          @SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
        else
          if flag == 'stag' then
            @SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
          else
          end
        end
            
          rescue HTTParty::Error => e
          puts 'HttParty::Error '+ e.message
          retry
        end while @SurveyQuotas.code != 200

        # Save quotas information for each survey
  
#       if @SurveyQuotas["SurveyStillLive"] == false then
#          puts '**************************** Deleting a closed survey'
#          survey.delete
#        else
          survey.SurveyStillLive = @SurveyQuotas["SurveyStillLive"]
          survey.SurveyStatusCode = @SurveyQuotas["SurveyStatusCode"]
          survey.SurveyQuotas = @SurveyQuotas["SurveyQuotas"]
#        end
         
      # Get new quota info by surveynumber and overwrite in Survey table
  
      # Save quotas information for each survey
          print '******************************** Updating quals and quota for existing Surveynumber: ', @surveynumber
          puts
          survey.save

      else
        # This survey has no remaining allocation. It should be marked as if this survey is not alive
        survey.SurveyStillLive = false   
        survey.save     
        
        print "********************* There is NO remaining allocation for this EXISTING survey number: ", @surveynumber
        puts
        
      end # end for total remaining in survey allocations 
      
      end # do the survey block
      
      else
        # Survey number does not exist. This is a new entry from allocation, get qualifications, quotas, and supplierlinks for it and create as new if the survey meets our biz requirements of countrylanguage, studytype, etc.        

 
 if ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 5) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 6) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 7) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 9)) && ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 1) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 13) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 14) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 15) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 16) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 17) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 19) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 21) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 23)) && ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["BidLengthOfInterview"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["BidLengthOfInterview"] < 41)) && (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"] != 67820) && (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"] != 66091) && (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"] != 65653) && (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"] != 98319) && (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"] != 101766) then 
         
        @newsurvey = Survey.new
        @newsurvey.SurveyName = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyName"]
        @newsurvey.SurveyNumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
        @newsurvey.SurveySID = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveySID"]
        @newsurvey.StudyTypeID = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"]
        @newsurvey.CountryLanguageID = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"]
        @newsurvey.BidIncidence = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["BidIncidence"]
        @newsurvey.LengthOfInterview = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["LengthOfInterview"]
        @newsurvey.BidLengthOfInterview = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["BidLengthOfInterview"]
        @newsurvey.CPI = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CPI"]
        @newsurvey.Conversion = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
        @newsurvey.TotalRemaining = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["TotalRemaining"]
        @newsurvey.OverallCompletes = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["OverallCompletes"]
        @newsurvey.SurveyMobileConversion = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyMobileConversion"]
      
   
   
        # Code for testing
  
        @SurveyName = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyName"]
        SurveyNumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
        print 'PROCESSING i =', i
        puts
        print 'SurveyName: ', @SurveyName, ' SurveyNumber: ', SurveyNumber, ' CountryLanguageID: ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"]
        puts
   
        # Assign an initial gross rank to the NEW survey
        # 10 is worst for the lowest conversion rate
        
        begin
          sleep(1)
          print '**************************** CONNECTING FOR GLOBAL STATS on NEW survey: ', SurveyNumber
          puts
          
          if flag == 'prod' then
            NewSurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+SurveyNumber.to_s+'/5458/Global/Trailing?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
          else
            if flag == 'stag' then
              NewSurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+SurveyNumber.to_s+'/5411/Global/Trailing?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            else
            end
          end
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
        end while NewSurveyStatistics.code != 200
        

        # For the NEW survey - Store GEEPC in SurveyQuotaCalcTypeID as an integer. Also set SurveyExactRank and SampleTypeID to keep track of unsuccessful and OQ attempts respectively.
        
        @newsurvey.SurveyExactRank = 0
        @newsurvey.SampleTypeID = 0
        
        print '******************* Effective GlobalEPC is = ', NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
        puts
        
        if NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] > 0.2 then
          @newsurvey.SurveyQuotaCalcTypeID = 1 # best kind
        else 
          if ((0 < NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]) && (NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] <= 0.2)) then
            @newsurvey.SurveyQuotaCalcTypeID = 2 # second best kind
          else
            @newsurvey.SurveyQuotaCalcTypeID = 5 # worst kind by GEEPC data
          end
        end


        
        if @updatesrankingapproach == 'EEPCFirst' then
          if NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] > 0.2 then
            @newsurvey.SurveyGrossRank = 1
            print '******************* Effective GlobalEPC is > 0.2 = ', NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
            puts
          else
            if ((0 < NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]) && (NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] <= 0.2)) then
              @newsurvey.SurveyGrossRank = 5
              print '******************* Effective GlobalEPC is <= 0.2 = ', NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
              puts
            else
              case IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
              when 0..5
                puts "Lowest Rank 20"
                @newsurvey.SurveyGrossRank = 20
              when 6..10
                puts "Rank 19"
                @newsurvey.SurveyGrossRank = 19
              when 11..15
                puts "Rank 18"
                @newsurvey.SurveyGrossRank = 18
              when 16..20
                puts "Rank 17"
                @newsurvey.SurveyGrossRank = 17
              when 21..25
                puts "Rank 16"
                @newsurvey.SurveyGrossRank = 16
              when 26..30
                puts "Rank 15"
                @newsurvey.SurveyGrossRank = 15
              when 31..35
                puts "Rank 14"
                @newsurvey.SurveyGrossRank = 14
              when 36..40
                puts "Rank 13"
                @newsurvey.SurveyGrossRank = 13
              when 41..45
                puts "Rank 12"
                @newsurvey.SurveyGrossRank = 12
              when 46..50
                puts "Rank 11"
                @newsurvey.SurveyGrossRank = 11
              when 51..55
                puts "Rank 10"
                @newsurvey.SurveyGrossRank = 10
              when 56..60
                puts "Rank 9"
                @newsurvey.SurveyGrossRank = 9
              when 61..65
                puts "Rank 8"
                @newsurvey.SurveyGrossRank = 8
              when 66..70
                puts "Rank 7"
                @newsurvey.SurveyGrossRank = 7
              when 71..75
                puts "Rank 6"
                @newsurvey.SurveyGrossRank = 6
              when 76..80
                puts "Rank 5"
                @newsurvey.SurveyGrossRank = 5
              when 81..85
                puts "Rank 4"
                @newsurvey.SurveyGrossRank = 4
              when 86..90
                puts "Rank 3"
                @newsurvey.SurveyGrossRank = 3
              when 91..95
                puts "Rank 2"
                @newsurvey.SurveyGrossRank = 2
              when 96..100
                puts "Highest Rank 1"
                @newsurvey.SurveyGrossRank = 1
              end # end case
              
            end # end of if EEPC is between 0 and 0.2
          end # end of, if EEPC is more than 0.2
          
        else # for 'ConversionFirst' approach
          
          case IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
            when 0..5
              puts "Lowest Rank 20"
              @newsurvey.SurveyGrossRank = 20
            when 6..10
              puts "Rank 19"
              @newsurvey.SurveyGrossRank = 19
            when 11..15
              puts "Rank 18"
              @newsurvey.SurveyGrossRank = 18
            when 16..20
              puts "Rank 17"
              @newsurvey.SurveyGrossRank = 17
            when 21..25
              puts "Rank 16"
              @newsurvey.SurveyGrossRank = 16
            when 26..30
              puts "Rank 15"
              @newsurvey.SurveyGrossRank = 15
            when 31..35
              puts "Rank 14"
              @newsurvey.SurveyGrossRank = 14
            when 36..40
              puts "Rank 13"
              @newsurvey.SurveyGrossRank = 13
            when 41..45
              puts "Rank 12"
              @newsurvey.SurveyGrossRank = 12
            when 46..50
              puts "Rank 11"
              @newsurvey.SurveyGrossRank = 11
            when 51..55
              puts "Rank 10"
              @newsurvey.SurveyGrossRank = 10
            when 56..60
              puts "Rank 9"
              @newsurvey.SurveyGrossRank = 9
            when 61..65
              puts "Rank 8"
              @newsurvey.SurveyGrossRank = 8
            when 66..70
              puts "Rank 7"
              @newsurvey.SurveyGrossRank = 7
            when 71..75
              puts "Rank 6"
              @newsurvey.SurveyGrossRank = 6
            when 76..80
              puts "Rank 5"
              @newsurvey.SurveyGrossRank = 5
            when 81..85
              puts "Rank 4"
              @newsurvey.SurveyGrossRank = 4
            when 86..90
              puts "Rank 3"
              @newsurvey.SurveyGrossRank = 3
            when 91..95
              puts "Rank 2"
              @newsurvey.SurveyGrossRank = 2
            when 96..100
              puts "Highest Rank 1"
              @newsurvey.SurveyGrossRank = 1
          end # end case
      
        end # end of rankingapproach switch

          # Before getting qualifications, quotas, and supplier links first check if there is any remaining total allocation for this NEW survey
        
          begin
            sleep(1)
            puts '**************************** CONNECTING FOR SUPPLIER ALLOCATIONS INFORMATION on NEW survey: ', SurveyNumber
            if flag == 'prod' then
              @NewSupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+SurveyNumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                @NewSupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
          end while @NewSupplierAllocations.code != 200

          if @NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"] > 0 then
          
            print '********************* There is total remaining allocation for this NEW survey number: ', SurveyNumber, ' in the amount of: ', @NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]
            puts

          # Get Survey Qualifications Information by SurveyNumber
          begin
            sleep(2)
            puts 'CONNECTING FOR QUALIFICATIONS INFORMATION of new survey'
 
          if flag == 'prod' then
            NewSurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
          else
            if flag == 'stag' then
              NewSurveyQualifications = HTTParty.get(base_url+'/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            else
            end
          end
 
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
          end while NewSurveyQualifications.code != 200

          # By default all users are qualified
    
          @newsurvey.QualificationAgePreCodes = ["ALL"]
          @newsurvey.QualificationGenderPreCodes = ["ALL"]
          @newsurvey.QualificationZIPPreCodes = ["ALL"]
          @newsurvey.QualificationRacePreCodes = ["ALL"]
          @newsurvey.QualificationEthnicityPreCodes = ["ALL"]  
          @newsurvey.QualificationEducationPreCodes = ["ALL"]  
          @newsurvey.QualificationHHIPreCodes = ["ALL"]  
          
          

          # Insert specific qualifications where required

          if NewSurveyQualifications["SurveyQualification"]["Questions"] == nil then
#          if NewSurveyQualifications["SurveyQualification"]["Questions"].empty? then
            puts '***************** SurveyQualifications or Questions is NIL'
            @newsurvey.QualificationAgePreCodes = ["ALL"]
            @newsurvey.QualificationGenderPreCodes = ["ALL"]
            @newsurvey.QualificationZIPPreCodes = ["ALL"]            
            @newsurvey.QualificationRacePreCodes = ["ALL"]
            @newsurvey.QualificationEthnicityPreCodes = ["ALL"]  
            @newsurvey.QualificationEducationPreCodes = ["ALL"]  
            @newsurvey.QualificationHHIPreCodes = ["ALL"]  
            
          else
            @NumberOfQualificationsQuestions = NewSurveyQualifications["SurveyQualification"]["Questions"].length-1
            print '@NumberOfQualificationsQuestions: ', @NumberOfQualificationsQuestions+1
            puts
    
            (0..@NumberOfQualificationsQuestions).each do |j|
              # Survey.Questions = NewSurveyQualifications["SurveyQualification"]["Questions"]
 #             puts NewSurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
              case NewSurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
                when 42
                  if flag == 'stag' then
                    print 'AGE: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationAgePreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 43
                  print 'GENDER: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  puts
                  @newsurvey.QualificationGenderPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 45
                  if flag == 'stag' then
#                    print 'ZIP: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
#                    puts
                  else
                  end
                  @newsurvey.QualificationZIPPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 47
                  if flag == 'stag' then
                    print 'HISPANIC->Ethnicity: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  # Note: FED calls our Ethnicity definition as HISPANIC. Adhering to our definition.
                  @newsurvey.QualificationEthnicityPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 113
                  if flag == 'stag' then
                    print 'ETHNICITY->Race: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  # Note: FED calls our Race definition as ETHNICITY. Adhering to our definition.
                  @newsurvey.QualificationRacePreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 633
                  if flag == 'stag' then
                    print 'STANDARD_EDUCATION: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationEducationPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 14785
                  if flag == 'stag' then
                    print 'STANDARD_HHI_US: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationHHIPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")  
                when 14887
                  if flag == 'stag' then
                    print 'STANDARD_HHI_INT: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationHHIPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")     
              end # case

            end #do      
          end # if
    
          # Get new Survey Quotas Information by SurveyNumber
          begin
            sleep(1)
            print 'CONNECTING FOR QUOTA INFORMATION for new survey: ', SurveyNumber
            puts
          
            if flag == 'prod' then
              @NewSurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                @NewSurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
          
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
            end while @NewSurveyQuotas.code != 200

            # Save quotas information for each survey

#           if @NewSurveyQuotas["SurveyStillLive"] == false then
#              @survey.delete
#            else
              @newsurvey.SurveyStillLive = @NewSurveyQuotas["SurveyStillLive"]
              @newsurvey.SurveyStatusCode = @NewSurveyQuotas["SurveyStatusCode"]
              @newsurvey.SurveyQuotas = @NewSurveyQuotas["SurveyQuotas"]
#            end
        
            # Get Supplierlinks for the survey
    
            begin
#            sleep(1)
              print 'PUTTING tO get SupplierLinks for the new survey = ', SurveyNumber
              puts
       
              if (flag == 'stag') then
                NewSupplierLink = HTTParty.put(base_url+'/Supply/v1/SupplierLinks/Update/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E',
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
                  NewSupplierLink = HTTParty.put(base_url+'/Supply/v1/SupplierLinks/Update/'+SurveyNumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702',
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
              end
            end
            
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
#            retry
            end while NewSupplierLink.code < 0

            if NewSupplierLink.code != 200 then
              print '**************************************************** SUPPLIERLINKS NOT AVAILABLE'
              puts
              # Do not save this survey
            else  
              print '******************* SUPPLIERLINKS ARE AVAILABLE: ', NewSupplierLink["SupplierLink"]
              puts
#             puts NewSupplierLink["SupplierLink"]["LiveLink"]
              @newsurvey.SupplierLink = NewSupplierLink["SupplierLink"]
              @newsurvey.CPI = NewSupplierLink["SupplierLink"]["CPI"]   
              print '**************************************************** SAVING THE NEW SURVEY IN DATABASE'
              puts
              
              # Finally save the new survey information in the database
              @newsurvey.save
            end
 
          else
            # This NEW survey does not have any total remaining completes. It is like the survey is not live for us.
            # We may not save it locally. DO NOTHING.
            print "********************* There is NO remaining allocation for this NEW survey number: ", IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
            puts
            
          end
          
          else
            print '******************************** This survey does not meet our biz requirements: ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
            puts
          end # download a new survey if the new survey qualifies for being suitable from countrylanguageID, studytypeID, and BidLOI criteria

      end # if @surveynumber exists  
      print 'Updating totalavailablesurveys at count i = ', i   
      puts  

    end # do loop of totalavailablesurveys (i)
    
    # Pause surveys not on the allocation list but are in local database
    
    
    surveysnottobedeleted = Array.new
    listofsurveynumbers = Array.new
    surveystobedeleted = Array.new
    
    Survey.all.each do |oldsurvey|
      listofsurveynumbers << oldsurvey.SurveyNumber
#      print 'Investigating Survey Number from the dbase: ', listofsurveynumbers
#      puts
      
      (0..totalavailablesurveys).each do |k|
        if IndexofAllocatedSurveys["SupplierAllocationSurveys"][k]["SurveyNumber"] == oldsurvey.SurveyNumber then
#          print 'Marked a survey to be ALIVE: ', oldsurvey.SurveyNumber
#          puts     
          surveysnottobedeleted << oldsurvey.SurveyNumber
         else
           # do nothing
#          SurveyStillLive = false
         end # if
#         print 'looping list of allocationsurveys, count:', k
#         puts
       end # do k
     end # do j
     
     print 'List of all surveys in DB', listofsurveynumbers
     puts
     print 'List of surveys not to be deleted', surveysnottobedeleted
     puts

     #   This section is there to remove old dead surveys.
    
     Survey.all.each do |oldsurvey|
       if surveysnottobedeleted.include? (oldsurvey.SurveyNumber) then
         # do nothing
       else
          surveystobedeleted << oldsurvey.SurveyNumber
#          print 'DELETING THIS SURVEY NUMBER NOT on Allocation LIST ', oldsurvey.SurveyNumber
#          puts
          oldsurvey.delete     
      end
    end # do oldsurvey
    
    print 'Surveys to be deleted', surveystobedeleted
    puts
    
    
#    Survey.where( "SurveyStillLive = ?", false ).each do |survey|
#    end

    timenow = Time.now
    print 'Time at end', timenow
    puts
    if (timenow - starttime) > 1800 then 
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
      puts
      timetorepeat = true
    else
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to sleep for 10 minutes since it takes about 20 mins to do a sweep.'
      puts
      sleep (10.minutes)
 #     sleep (1800 - (timenow - starttime)).round
      timetorepeat = true
    end

end while timetorepeat