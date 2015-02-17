require 'httparty'

# Set flag to 'prod' to use production and 'stag' for staging base URL

flag = 'prod'


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


# Initialize timer outside of the repeat cycle to maintain ranking frequency
@lastrankingtime = Time.now


# Download the full allocations index

begin

  starttime = Time.now
  print 'At start at', starttime
  puts
  
  begin
    sleep(1)
    puts '************ CONNECTING FOR index of ALL ALLOCATED SURVEYS' 
 
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


  # Check if any survey has allocation remaining, and get current qualifications and current quota.


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
        
        
        # First check if there are any completes needed.
        
        survey.TotalRemaining = @SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]

        if @SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"] > 0 then
          
          print "********************* There is total remaining allocation for this EXISTING survey number: ", @surveynumber, ' in the amount of: ', @SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]
          puts
          

          # Update GEPC and Conversion information for the Existing survey. Ranking script every 20 mins will use the data to update ranks.
          
          
          begin
            sleep(1)
            print '**************************** CONNECTING FOR GLOBAL STATS (GEPC) on EXISTING survey: ', @surveynumber
            puts
        
            if flag == 'prod' then
              SurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+@surveynumber.to_s+'/5458/Global/Trailing?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                SurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+@surveynumber.to_s+'/5411/Global/Trailing?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
          end while SurveyStatistics.code != 200
      

          
          survey.GEPC = SurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
          survey.Conversion = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
                    
          print '******************* Effective GEPC is: ', survey.GEPC, ' Conversion is: ', survey.Conversion
          puts

     
          
#          if (survey.SurveyExactRank > 10) || (survey.CompletedBy.length > 0) then # if 20
            # do nothing
#          else # If 20
            # update Rank with new Conversion data
#            case IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
#              when 0..5
#                puts "Lowest Rank 20"
#                survey.SurveyGrossRank = 20
#              when 6..10
#                puts "Rank 19"
#                survey.SurveyGrossRank = 19
#              when 11..15
#                puts "Rank 18"
#                survey.SurveyGrossRank = 18
#              when 16..20
#                puts "Rank 17"
#                survey.SurveyGrossRank = 17
#              when 21..25
#                puts "Rank 16"
#                survey.SurveyGrossRank = 16
#              when 26..30
#                puts "Rank 15"
#                survey.SurveyGrossRank = 15
#              when 31..35
#                puts "Rank 14"
#                survey.SurveyGrossRank = 14
#              when 36..40
#                puts "Rank 13"
#                survey.SurveyGrossRank = 13
#              when 41..45
#                puts "Rank 12"
#                survey.SurveyGrossRank = 12
#              when 46..50
#                puts "Rank 11"
#                survey.SurveyGrossRank = 11
#              when 51..55
#                puts "Rank 10"
#                survey.SurveyGrossRank = 10
#              when 56..60
#                puts "Rank 9"
#                survey.SurveyGrossRank = 9
#              when 61..65
#                puts "Rank 8"
#                survey.SurveyGrossRank = 8
#              when 66..70
#                puts "Rank 7"
#                survey.SurveyGrossRank = 7
#              when 71..75
#                puts "Rank 6"
#                survey.SurveyGrossRank = 6
#              when 76..80
#                puts "Rank 5"
#                survey.SurveyGrossRank = 5
#              when 81..85
#                puts "Rank 4"
#                survey.SurveyGrossRank = 4
#              when 86..90
#                puts "Rank 3"
#                survey.SurveyGrossRank = 3
#              when 91..95
#                puts "Rank 2"
#                survey.SurveyGrossRank = 2
#              when 96..100
#                puts "Highest Rank 1"
#                survey.SurveyGrossRank = 1
#            end # end case
            
            
#          end # if 20 'if (survey.SurveyExactRank > 10) || (survey.CompletedBy.length > 0) then'

 
 
 
 
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
      
      # Change HHC to Employment
      
      

      survey.QualificationAgePreCodes = ["ALL"]
      survey.QualificationGenderPreCodes = ["ALL"]
      survey.QualificationZIPPreCodes = ["ALL"]      
      survey.QualificationRacePreCodes = ["ALL"]
      survey.QualificationEthnicityPreCodes = ["ALL"]  
      survey.QualificationEducationPreCodes = ["ALL"]  
      survey.QualificationHHIPreCodes = ["ALL"]
      survey.QualificationHHCPreCodes = ["ALL"]


      # Update specific qualifications to be current information
      
      # Change HHC to Employment
      
      

      if SurveyQualifications["SurveyQualification"]["Questions"] == nil then
        
        puts '****************** SurveyQualifications or Questions is NIL'
        survey.QualificationAgePreCodes = ["ALL"]
        survey.QualificationGenderPreCodes = ["ALL"]
        survey.QualificationZIPPreCodes = ["ALL"]    
        survey.QualificationRacePreCodes = ["ALL"]
        survey.QualificationEthnicityPreCodes = ["ALL"]  
        survey.QualificationEducationPreCodes = ["ALL"]  
        survey.QualificationHHIPreCodes = ["ALL"]
        survey.QualificationHHCPreCodes = ["ALL"]
       
      else
        @NumberOfQualificationsQuestions = SurveyQualifications["SurveyQualification"]["Questions"].length-1
        print '************** @NumberOfQualificationsQuestions: ', @NumberOfQualificationsQuestions+1
        puts
            
        (0..@NumberOfQualificationsQuestions).each do |j|
        
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
              survey.QualificationHHCPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")  


            when 643
              if flag == 'stag' then
                print '------------------------------------------------------------->> STANDARD_INDUSTRY: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              
    
                         
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
  
          survey.SurveyStillLive = @SurveyQuotas["SurveyStillLive"]
          survey.SurveyStatusCode = @SurveyQuotas["SurveyStatusCode"]
          survey.SurveyQuotas = @SurveyQuotas["SurveyQuotas"]
         
      # Get new quota info by surveynumber and overwrite in Survey table
  
      # Save quotas information for each survey
          print '******************************** Updating quals and quota for existing Surveynumber: ', @surveynumber
          puts
          survey.save!
 
       else
        # This survey has no remaining allocation. It should be marked as if this survey is not alive
        survey.SurveyStillLive = false   
        survey.save!     
        
        print "********************* There is NO remaining allocation for this EXISTING survey number: ", @surveynumber
        puts
        
        end # end for total remaining in survey allocations 
      
      end # do the survey block
      
      else
        # Survey number does not exist. This is a NEW entry from allocation, get qualifications, quotas, and supplierlinks for it and create as new if the survey meets our biz requirements of countrylanguage, studytype, etc.        

 
        if (((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 5) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 6) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 7) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 9)) && ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 1) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 11) ||  (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 13) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 14) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 15) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 16) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 17) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 19) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 21) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 23))) then
      
          print '---------------------> Matches: CountryLanguageID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == nil ) ||      (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 5) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 6) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 7) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 9))
          puts

          print '---------------------> Matches: StudyTypeID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 1) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 11) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 13) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 14) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 15) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 16) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 17) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 19) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 21) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 23))
puts
   
         print 'Matches: SurveyNumber is ', @surveynumber
         puts
         print '----------------->Matches:  StudyTypeID = ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"]
         puts
      
         
        @newsurvey = Survey.new
        @newsurvey.SurveyName = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyName"]
        @newsurvey.SurveyNumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
        @newsurvey.SurveySID = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveySID"]
        @newsurvey.StudyTypeID = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"]
        @newsurvey.CountryLanguageID = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"]
        @newsurvey.BidIncidence = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["BidIncidence"]
        @newsurvey.LengthOfInterview = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["LengthOfInterview"]
        @newsurvey.BidLengthOfInterview = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["BidLengthOfInterview"]      
        @newsurvey.Conversion = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
        @newsurvey.TotalRemaining = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["TotalRemaining"]
        @newsurvey.OverallCompletes = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["OverallCompletes"]
        @newsurvey.SurveyMobileConversion = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyMobileConversion"]
        @newsurvey.FailureCount = 0
        @newsurvey.OverQuotaCount = 0
        @newsurvey.KEPC = 0.0
        
        @newsurvey.NumberofAttemptsAtLastComplete = 0
        @newsurvey.TCR = 0.0
      
   
   
        # Code for testing
  
        @SurveyName = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyName"]
        SurveyNumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]   # same as @surveynumber
        
        print 'PROCESSING i =', i
        puts
        print 'SurveyName: ', @SurveyName, ' SurveyNumber: ', SurveyNumber, ' CountryLanguageID: ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"]
        puts
   

        
#        if @updatesrankingapproach == 'EEPCFirst' then
#          if NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] > 0.2 then
#            @newsurvey.SurveyGrossRank = 1
#            print '******************* Effective GlobalEPC is > 0.2 = ', NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
#            puts
#          else
#            if ((0 < NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]) && (NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] <= 0.2)) then
#              @newsurvey.SurveyGrossRank = 5
#              print '******************* Effective GlobalEPC is <= 0.2 = ', NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
#              puts
#            else
#              case IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
#              when 0..5
#                puts "Lowest Rank 20"
#                @newsurvey.SurveyGrossRank = 20
#              when 6..10
#                puts "Rank 19"
#                @newsurvey.SurveyGrossRank = 19
#              when 11..15
#                puts "Rank 18"
#                @newsurvey.SurveyGrossRank = 18
#              when 16..20
#                puts "Rank 17"
#                @newsurvey.SurveyGrossRank = 17
#              when 21..25
#                puts "Rank 16"
#                @newsurvey.SurveyGrossRank = 16
#              when 26..30
#                puts "Rank 15"
#                @newsurvey.SurveyGrossRank = 15
#              when 31..35
#                puts "Rank 14"
#                @newsurvey.SurveyGrossRank = 14
#              when 36..40
#                puts "Rank 13"
#                @newsurvey.SurveyGrossRank = 13
#              when 41..45
#                puts "Rank 12"
#                @newsurvey.SurveyGrossRank = 12
#              when 46..50
#                puts "Rank 11"
#                @newsurvey.SurveyGrossRank = 11
#              when 51..55
#                puts "Rank 10"
#                @newsurvey.SurveyGrossRank = 10
#              when 56..60
#                puts "Rank 9"
#                @newsurvey.SurveyGrossRank = 9
#              when 61..65
#                puts "Rank 8"
#                @newsurvey.SurveyGrossRank = 8
#              when 66..70
#                puts "Rank 7"
#                @newsurvey.SurveyGrossRank = 7
#              when 71..75
#                puts "Rank 6"
#                @newsurvey.SurveyGrossRank = 6
#              when 76..80
#                puts "Rank 5"
#                @newsurvey.SurveyGrossRank = 5
#              when 81..85
#                puts "Rank 4"
#                @newsurvey.SurveyGrossRank = 4
#              when 86..90
#                puts "Rank 3"
#                @newsurvey.SurveyGrossRank = 3
#              when 91..95
#                puts "Rank 2"
#                @newsurvey.SurveyGrossRank = 2
#              when 96..100
#                puts "Highest Rank 1"
#                @newsurvey.SurveyGrossRank = 1
#              end # end case
              
#            end # end of if EEPC is between 0 and 0.2
#          end # end of, if EEPC is more than 0.2
          
#        else # for 'ConversionFirst' approach
          
#          case IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
#            when 0..5
#              puts "Lowest Rank 20"
#              @newsurvey.SurveyGrossRank = 20
#            when 6..10
#              puts "Rank 19"
#              @newsurvey.SurveyGrossRank = 19
#            when 11..15
#              puts "Rank 18"
#              @newsurvey.SurveyGrossRank = 18
#            when 16..20
#              puts "Rank 17"
#              @newsurvey.SurveyGrossRank = 17
#            when 21..25
#              puts "Rank 16"
#              @newsurvey.SurveyGrossRank = 16
#            when 26..30
#              puts "Rank 15"
#              @newsurvey.SurveyGrossRank = 15
#            when 31..35
#              puts "Rank 14"
#              @newsurvey.SurveyGrossRank = 14
#            when 36..40
#              puts "Rank 13"
#              @newsurvey.SurveyGrossRank = 13
#            when 41..45
#              puts "Rank 12"
#              @newsurvey.SurveyGrossRank = 12
#            when 46..50
#              puts "Rank 11"
#              @newsurvey.SurveyGrossRank = 11
#            when 51..55
#              puts "Rank 10"
#              @newsurvey.SurveyGrossRank = 10
#            when 56..60
#              puts "Rank 9"
#              @newsurvey.SurveyGrossRank = 9
#            when 61..65
#              puts "Rank 8"
#              @newsurvey.SurveyGrossRank = 8
#            when 66..70
#              puts "Rank 7"
#              @newsurvey.SurveyGrossRank = 7
#            when 71..75
#              puts "Rank 6"
#              @newsurvey.SurveyGrossRank = 6
#            when 76..80
#              puts "Rank 5"
#              @newsurvey.SurveyGrossRank = 5
#            when 81..85
#              puts "Rank 4"
#              @newsurvey.SurveyGrossRank = 4
#            when 86..90
#              puts "Rank 3"
#              @newsurvey.SurveyGrossRank = 3
#            when 91..95
#              puts "Rank 2"
#              @newsurvey.SurveyGrossRank = 2
#            when 96..100
#              puts "Highest Rank 1"
#              @newsurvey.SurveyGrossRank = 1
#          end # end case
      
#        end # end of rankingapproach switch



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
            
            @newsurvey.TotalRemaining = @NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]

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
               
          # Change HHC to Employment
    
          @newsurvey.QualificationAgePreCodes = ["ALL"]
          @newsurvey.QualificationGenderPreCodes = ["ALL"]
          @newsurvey.QualificationZIPPreCodes = ["ALL"]
          @newsurvey.QualificationRacePreCodes = ["ALL"]
          @newsurvey.QualificationEthnicityPreCodes = ["ALL"]  
          @newsurvey.QualificationEducationPreCodes = ["ALL"]  
          @newsurvey.QualificationHHIPreCodes = ["ALL"]
          @newsurvey.QualificationHHCPreCodes = ["ALL"]
          
          # Insert specific qualifications where required
          
          # Change HHC to Employment

          if NewSurveyQualifications["SurveyQualification"]["Questions"] == nil then
            puts '***************** SurveyQualifications or Questions is NIL'
            @newsurvey.QualificationAgePreCodes = ["ALL"]
            @newsurvey.QualificationGenderPreCodes = ["ALL"]
            @newsurvey.QualificationZIPPreCodes = ["ALL"]            
            @newsurvey.QualificationRacePreCodes = ["ALL"]
            @newsurvey.QualificationEthnicityPreCodes = ["ALL"]  
            @newsurvey.QualificationEducationPreCodes = ["ALL"]  
            @newsurvey.QualificationHHIPreCodes = ["ALL"]
            @newsurvey.QualificationHHCPreCodes = ["ALL"]
            
          else
            @NumberOfQualificationsQuestions = NewSurveyQualifications["SurveyQualification"]["Questions"].length-1
            print '@NumberOfQualificationsQuestions: ', @NumberOfQualificationsQuestions+1
            puts
    
            (0..@NumberOfQualificationsQuestions).each do |j|                                     #do15

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
                                
                when 7064
                  if flag == 'stag' then
                    print '------------------------------------------------------------------->> Parental_Status_Standard: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                when 1249
                  if flag == 'stag' then
                    print '----------------------------------------------------------------->> Age_and_Gender_of_Child: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                when 2189
                  if flag == 'stag' then
                    print '------------------------------------------------------------>> STANDARD_EMPLOYMENT: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  p '------------------------------------------------------------>> Rename HHComp to STANDARD_EMPLOYMENT: '
                  @newsurvey.QualificationHHCPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")  
                when 643
                  if flag == 'stag' then
                    print '------------------------------------------------------------->> STANDARD_INDUSTRY: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end     
                  
              end # case

            end #do15 for j      
          end # if SurveyQuals == nil
    
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

              @newsurvey.SurveyStillLive = @NewSurveyQuotas["SurveyStillLive"]
              @newsurvey.SurveyStatusCode = @NewSurveyQuotas["SurveyStatusCode"]
              @newsurvey.SurveyQuotas = @NewSurveyQuotas["SurveyQuotas"]
                           
        
            # Get Supplierlinks for the survey
    
            begin
#            sleep(1)
              print 'PUT to get SupplierLinks for the new survey = ', SurveyNumber
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
#             retry
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
              
           
              # Assign an initial gross rank to the NEW survey in 101-200 or 301-400 based on GCR
        
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
        

              # For the NEW survey - save GEPC. It will be used to compute GCR. Also set SurveyExactRank and SampleTypeID to keep track of unsuccessful and OQ attempts respectively.
        
              @newsurvey.GEPC = NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
              @newsurvey.SurveyExactRank = 0
              @newsurvey.SampleTypeID = 0
        
              
              # Assign a GCR to the new survey since we now have its CPI from SupplierLink
              
              if @newsurvey.CPI > 0 then
                @newGCR = @newsurvey.GEPC / @newsurvey.CPI
              else
                @newGCR = @newsurvey.GEPC
              end
              
               
               print '******************* Effective GlobalEPC for this new survey is = ', @newsurvey.GEPC, ' GCR is: ', @newGCR
               puts
        
        
              if @newGCR >= 0.1 then
      #          @newsurvey.SurveyQuotaCalcTypeID = 1 # best kind
          
                if (@newGCR >= 1) then
                  @newsurvey.SurveyGrossRank = 201
                  print "Assigned NEW/GCR>=0.1 survey rank: ", @newsurvey.SurveyGrossRank, " GCR = ", @newGCR
                  puts
             
                else
            
                  @newsurvey.SurveyGrossRank = 300-(100*@newGCR)
                  print "Assigned NEW/GEPC>=0.1 survey rank: ", @newsurvey.SurveyGrossRank, " GCR = ", @newGCR
                  puts
                end
          
              else
              end
        
              if @newGCR < 0.1 then
      #          @newsurvey.SurveyQuotaCalcTypeID = 5 # worst kind
        
                if @newsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                  p "Found a survey with Conversion = 0"
                  @newsurvey.SurveyGrossRank = 500
                else
          
                  @newsurvey.SurveyGrossRank = 401+(100-@newsurvey.Conversion)
                  print "Assigned NEW/GEPC=5 survey rank: ", @newsurvey.SurveyGrossRank, " GCR = ", @newGCR
                  puts
                end
          
              else
              end       
              
              
              # Finally save the new survey information in the database
              @newsurvey.save!
            end # SupplierLinks Available
 
          else # TotalNumberOfAllocations for the new survey
            
            # This NEW survey does not have any total remaining completes. It is like the survey is not live for us.
            # We may not save it locally. DO NOTHING.
            print "********************* There is NO remaining allocation for this NEW survey number: ", IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
            puts
            
          end # TotalNumberOfAllocations for the new survey
          
        else # download a new survey
          
            print '******************************** This survey does not meet our biz requirements: ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
            puts
            
            print '---------------------> Does NOT Match: CountryLanguageID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 5) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 6) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 7) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 9))
            puts

            print '---------------------> Does NOT Match: StudyTypeID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 1) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 11) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 13) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 14) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 15) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 16) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 17) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 19) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 21) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 23))
  
               puts
               
               print '----------------->Does NOT Match:  StudyTypeID = ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"]
               puts
            
            
        end # download a new survey if the new survey qualifies for being suitable from countrylanguageID, studytypeID, and BidLOI criteria


      end # if @surveynumber exists  
      print '******************* Updating totalavailablesurveys at count i = ', i   
      puts
  
  
  
  
      # RANK the stack after every 20 minutes    
           
#      if (i == 30000) || ((Time.now - @lastrankingtime) >= 300000) then    
      
      if (i == 1) || ((Time.now - @lastrankingtime) >= 1200) then    
          
        @lastrankingtime = Time.now
        
        print "******************** Last ranking time: ", @lastrankingtime
        puts        
        
        Survey.all.each do |toberankedsurvey|
    
        # Safety: 1-95
        if (0 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 95) then
          
        # Only low CPI TCR > 0.05 (fast converters) in this group. Surveys arrive in TCR order. If they do not perform move them to Horrible.
          
          @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
          
          if (@toberankedsurveyNumberofAttemptsSinceLastComplete > 20) then  # worst than 5% conversion rate i.e. 20 more after they were moved out of New
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              p "Found a toberankedsurvey with Conversion = 0"
              toberankedsurvey.Conversion = 700
            else

              toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
              print "Assigned Safety survey to Horrible: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts
              toberankedsurvey.TCR = 1.0 / @toberankedsurveyNumberofAttemptsSinceLastComplete
              toberankedsurvey.label = 'H: CPI<1.5 and TCR<0.5'
            end
            
          else
            
            toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.TCR * 100)
            print "Reposition Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            toberankedsurvey.label = 'S: TCR>1'
            
          end
          
        else # not in 1-95 rank range
        end # not in 1-95 rank range
        
        # Custom: 96-100
        if (95 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 100) then
        # do nothing. surveys are put here manually to give them quick exposure to traffic
        else
        end  # not in 96-100 range
      
        # Fast Converters 101-200        
        if (100 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 200) then
          
          # Only high CPI and TCR > 0.05 (fast converters) in this group. Surveys arrive in TCR order. If they do not perform move them to OldTimers & Bad.
          
          @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
          
          if (@toberankedsurveyNumberofAttemptsSinceLastComplete > 20) then
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              p "Found a toberankedsurvey with Conversion = 0"
              toberankedsurvey.Conversion = 600
            else
            
              toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
              print "Assigned Fast survey to Old Timer: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts
              toberankedsurvey.TCR = 1.0 / @toberankedsurveyNumberofAttemptsSinceLastComplete
              toberankedsurvey.label = 'OT: TCR<0.5'
            end
            
          else
            
            toberankedsurvey.SurveyGrossRank = 200 - (toberankedsurvey.TCR * 100)
            print "Reposition Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            toberankedsurvey.label = 'F: TCR>1'
            
          end
          
          
    
#          toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length.to_f/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))
    
#          if 0.02 <= toberankedsurvey.KEPC then
            
      
            # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
#            if toberankedsurvey.KEPC * 100 >= 100 then
#              toberankedsurvey.SurveyGrossRank = 1
#              print "Assigned Top toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts
#            else
#              toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
#              print "Assigned Top toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end

#         else
#         end



    
 #         if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    
    
#            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#              p "Found a toberankedsurvey with Conversion = 0"
#              toberankedsurvey.Conversion = 1
#            else
#            end
      
#            toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
#            print "Updated existing 1-100 ranked toberankedsurvey to: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            puts
#          end
    
#          if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then  
    
#            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#              p "Found a toberankedsurvey with Conversion = 0"
#              toberankedsurvey.Conversion = 1
#            else
#            end
      
#            toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
#            print "Updated existing 1-100 ranked toberankedsurvey to: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#            puts
#          end
    
        else # not in 101-200 rank range
        end # not in 101-200 rank range
  
        # New+GCR>=0.01 201-300
        if (200 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 300) then
          
          # This is the place for new surveys to be tested with 10 hits. They move to Fast or Try more if they do not complete in 10. If they turn GCR>=0.01 then move them to GCR<0.01         
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.10) then # (1 in 10 hits)
            
            if (toberankedsurvey.CPI > 1.49) then
            
              toberankedsurvey.SurveyGrossRank = 200 - (toberankedsurvey.TCR * 100)
              print "Assigned New survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>1'
            else
            
                toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.TCR * 100)
                print "Assigned Top survey to Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'S: TCR>1 & CPI<1.5'
              
            end 
            
          else # Completes > 0 or TCR > 0.1
          end # Completes > 0 or TCR > 0.1
          
          if (toberankedsurvey.CompletedBy.length == 0) then
            
            if toberankedsurvey.CPI > 0 then
              @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
            else
              @GCR = toberankedsurvey.GEPC
            end

            if (@GCR < 0.01) then
  
              toberankedsurvey.SurveyGrossRank = 500-(100*@GCR)
              print "Assigned NEW/GCR>=0.01 survey to GCR<0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts
              toberankedsurvey.label = 'GCR<0.01'
              
            else # GCR>=0.01
      
                if (toberankedsurvey.SurveyExactRank > 10) then
                  
                  if (@GCR >= 1) then
                    toberankedsurvey.SurveyGrossRank = 301
                    print "Assigned GCR<0.01 to GCR>=0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts 
                    toberankedsurvey.label = 'TM: Hits>10'
                  else
    
                    toberankedsurvey.SurveyGrossRank = 400-(100*@GCR)
                    print "Assigned NEW/GCR>0.01 to Try More: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts    
                    toberankedsurvey.label = 'TM: Hits>10'
                  end
               
                else # less than 10 hits
                  
                  # do nothing until it gets 10 hits, reposition within 201-300
                               
                  if (@GCR >= 1) then
                    toberankedsurvey.SurveyGrossRank = 201
                    print "Repositioned New/GCR>=0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts 
                    toberankedsurvey.label = 'NEW/GCR>0.01: Repositioned'
                 
                  else
                  
                    toberankedsurvey.SurveyGrossRank = 300-(100*@GCR)
                    print "Repositioned NEW/GCR>0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts    
                    toberankedsurvey.label = 'NEW/GCR>0.01: Repositioned'
                  end
                  
                end # more than 10 hits on a GCR>=0.01
              
            end # GCR<0.01
              
          else # completes = 0
          end # completes = 0
                    

          # OLD GEPC=5
          #if (300 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 400) then
#          if toberankedsurvey.CompletedBy.length > 0 then
      
#            toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length.to_f/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))
      
            # Unless KEPC > 1 it will be ordered by KEPC value in Top tier. It will always be above 98
#            if toberankedsurvey.KEPC * 100 >= 100 then
#              toberankedsurvey.SurveyGrossRank = 1
#              print "Assigned NEW toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            else
#              toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
#              print "Assigned NEW toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end   
      
#          else # for 0 number of completes
      
#            if toberankedsurvey.SurveyQuotaCalcTypeID == 5 then
        
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
#              print "Assigned NEW toberankedsurvey a GEPC=5 tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
        
#            else # GEPC = 1 or 2
      
#              if toberankedsurvey.SurveyExactRank <= 10 then # No. of hits
        
                # do nothing - let it get few more hits
        
#              else # No. of hits > 10
        
                # does not look like a fast converter - move it to 'Try More' group
        
#                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                  p "Found a toberankedsurvey with Conversion = 0"
#                  toberankedsurvey.Conversion = 1
#                else
#                end
      
#                toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
#                print "Assigned NEW toberankedsurvey rank to Try More tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts   
          
#              end # No. of hits
        
#            end # GEPC = 5
      
#          end # end for number of completes


    
        else # not in 201-300 rank range
        end # not in 201-300 rank range
    
        # Try More 301-400
        if (300 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 400) then    
          
          # These surveys are here to get another 10 attempts (10 to 20). If they convert move them to Fast else take them to Horrible                  
            
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then
            
            if (toberankedsurvey.CPI > 1.49) then
            
              toberankedsurvey.SurveyGrossRank = 200 - (toberankedsurvey.TCR * 100)
              print "Assigned Try more survey to Top: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>0.5'
          
            else   
            
                toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.TCR * 100)
                print "Assigned Try more survey to Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'S: TCR>0.5'
              
            end 
            
          else # Completes > 0 or TCR > 0.05
          end # Completes > 0 or TCR > 0.05
          
          if (toberankedsurvey.CompletedBy.length == 0) then
            
            
            if toberankedsurvey.CPI > 0 then
              @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
            else
              @GCR = toberankedsurvey.GEPC
            end
                          
            if toberankedsurvey.SurveyExactRank <= 20 then # No. of hits
        
              # do nothing - let it get 20 hits. Reposition for updated GCR
             
              if (@GCR >= 1) then
                toberankedsurvey.SurveyGrossRank = 301
                print "Repositioned TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'TM: Repositioned'
                 
              else
                
                toberankedsurvey.SurveyGrossRank = 400-(100*@GCR)
                print "Repositioned TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts    
                toberankedsurvey.label = 'TM: Repositioned'
              end
                
            else # No. of hits > 20
        
              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                p "Found a toberankedsurvey with Conversion = 0"
                toberankedsurvey.Conversion = 700
              else
      
                toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
                print "Assigned a Try More to Horrible: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts   
                toberankedsurvey.label = 'H: Hits>20, TCR=0'
              end
          
            end # No. of hits
          
          else # number of completes = 0
          end # number of completes = 0
            
    
            
#          if toberankedsurvey.CompletedBy.length > 0 then
      
#            toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length.to_f/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))     
      
#            if 0.02 <= toberankedsurvey.KEPC then   
        
              # Unless KEPC > 1 it will be ordered by KEPC value in Top tier. It will always be above 98
#              if toberankedsurvey.KEPC * 100 >= 100 then
#                toberankedsurvey.SurveyGrossRank = 1
#                print "Assigned Try More toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              else
#                toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
#                print "Assigned Try More toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              end   
#        
#            else
#            end
#          
#            if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then
#    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
#              print "Assigned existing Try More toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end
      
#            if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then    
    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
#              print "Assigned existing Try More toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end 
      
#          else # for number of completes
      
#            if toberankedsurvey.SurveyQuotaCalcTypeID == 5 then
        
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
#              print "Assigned existing Try More toberankedsurvey a GEPC=5 tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
        
#            else # GEPC = 5
      
#              if toberankedsurvey.SurveyExactRank <= 20 then # No. of hits
        
                # do nothing - let it get few more hits
        
#              else # No. of hits > 20
        
                # is a bad converter - move it to 'Try More' group
        
#                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                  p "Found a toberankedsurvey with Conversion = 0"
#                  toberankedsurvey.Conversion = 1
#                else
#                end
      
#                toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
#                print "Assigned a Try More toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts   
          
#              end # No. of hits
        
#            end # GEPC = 5
      
#          end # end for number of completes


    
        else # not in rank 401-500 range
        end # not in rank 301-400 range
    
        # New+GCR<0.01 401-500
        if (400 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 500) then
        
          # This is the place for new GCR<0.01 surveys. If they make TCR>0.5 then move to Fast or Safety. Move to OldTimers and Bad if TCR<0.5 but more than 0. They move to Horrible if they do not complete in 10. If they turn GCR>=0.01 then move them to GCR>=0.01.        
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then # (1 in 10 hits)
          
            if (toberankedsurvey.CPI > 1.49) then
          
              toberankedsurvey.SurveyGrossRank = 200 - (toberankedsurvey.TCR * 100)
              print "Assigned GCR<0.01 survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>0.05 from GCR>=0.01'
          
            else   

                toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.TCR * 100)
                print "Assigned GCR<0.01 survey to Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'S: TCR>0.05 from GCR<0.01'
            
            end 
            
          else # Completes > 0 or TCR > 0.05
          end # Completes > 0 or TCR > 0.05
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.05)
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              p "Found a toberankedsurvey with Conversion = 0"
              toberankedsurvey.Conversion = 600
            
            else

              toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
              print "Assigned New/GCR<0.01 survey rank to OldTimers+Bad: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts    
              toberankedsurvey.label = 'OT/B: 0<TCR<0.05'
            end
            
          else
          end
        
          if (toberankedsurvey.CompletedBy.length == 0) then
            
            if toberankedsurvey.CPI > 0 then
              @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
            else
              @GCR = toberankedsurvey.GEPC
            end
          
            if (@GCR>= 0.01) then

              if (@GCR >= 1) then
                toberankedsurvey.SurveyGrossRank = 201
                print "Assigned GCR<0.01 to GCR>=0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts 
                toberankedsurvey.label = 'GCR>=0.01: GCR changed'
                 
              else
                
                toberankedsurvey.SurveyGrossRank = 300-(100*GCR)
                print "Assigned GCR<0.1 to GCR>=0.1: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'GCR>=0.1: GCR changed'
              end
            
            else # (GCR<0.01)
    
                if (toberankedsurvey.SurveyExactRank > 10) then
            
                  if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                    toberankedsurvey.SurveyGrossRank = 700
                    print "Assigned New/GCR<0.01 survey rank to Horrible: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts
                  
                  else
  
                    toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
                    print "Assigned New/GCR<0.01 survey rank to Horrible: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts    
                    toberankedsurvey.label = 'H: From GCR<0.01'
                  end
       
                else
                
                # wait until there are 10 attempts, Reposition within 401-500 block                
                
                  if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                    toberankedsurvey.SurveyGrossRank = 500
                    print "Repositioned New/GCR<0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts
              
                  else
                
                    toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
                    print "Repositioned New/GCR<0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts    
                    toberankedsurvey.label = 'GCR<0.01: Repositioned'
                  end         
                
                end # more than 10 hits on a GCR>0.01
            
            end # GCR<0.01
            
          else # completes = 0
          end # completes = 0
         
 
        # Old GEPC =5
#        if (300 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 400) then
    
#          if toberankedsurvey.CompletedBy.length > 0 then
      
#            toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length.to_f/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))     
      
#            if 0.02 <= toberankedsurvey.KEPC then   
        
              # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
#              if toberankedsurvey.KEPC * 100 >= 100 then
#                toberankedsurvey.SurveyGrossRank = 1
#                print "Assigned GEPC=5 toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              else
#                toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
#                print "Assigned GEPC=5 toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              end
        
#            else
#            end
      
#            if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    
    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
#      
#              toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
#              print "Assigned existing GEPC=5 toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end
       
#            if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then   
    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
#              print "Assigned existing GEPC=5 toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end 
      
#          else # for number of completes
      
#            if toberankedsurvey.SurveyQuotaCalcTypeID == 5 then
        
        
#            else # GEPC = 1 or 2 
      
#              if toberankedsurvey.SurveyExactRank == 0 then # No. of hits
        
#                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                  p "Found a toberankedsurvey with Conversion = 0"
#                  toberankedsurvey.Conversion = 1
#                else
#                end
      
#                toberankedsurvey.SurveyGrossRank = 101+(100-toberankedsurvey.Conversion)
#                print "Assigned existing GEPC=5 toberankedsurvey a New Survey tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
        
#              else # No. of hits = 0
#              end
          
#              if (0 < toberankedsurvey.SurveyExactRank) &&  (toberankedsurvey.SurveyExactRank <= 10) then # No. of hits 1-10
#        
#                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                  p "Found a toberankedsurvey with Conversion = 0"
#                  toberankedsurvey.Conversion = 1
#                else
#                end
#      
#                toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
#                print "Assigned existing GEPC=5 toberankedsurvey a Try More Survey tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
#            
#              else # No. of hits is 1-10
#              end
        
        
#              if (10 < toberankedsurvey.SurveyExactRank) &&  (toberankedsurvey.SurveyExactRank <= 20) then # No. of hits 11-20
        
                # is a bad converter - move it to 'Try More' group
        
#                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                  p "Found a toberankedsurvey with Conversion = 0"
#                  toberankedsurvey.Conversion = 1
#                else
#                end
      
#                toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
#                print "Assigned a GEPC=5 toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts   
          
#              else # No. of hits is 11-20
#              end
          
        
#              if (20 < toberankedsurvey.SurveyExactRank) then # No. of hits 11-20
        
                # is a horrible converter - move it to Horrible group
        
#                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                  p "Found a toberankedsurvey with Conversion = 0"
#                  toberankedsurvey.Conversion = 1
#                else
#                end
      
#                toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
#                print "Assigned a GEPC=5 toberankedsurvey a Horrible tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts   
          
#              else # No. of hits is 20+
#              end
        
        
#            end # GEPC = 5
      
#          end # end for number of completes
    
#        else # not in rank range
#        end # not in rank range
          
          
        else # not in 301-400 rank range
        end # not in 301-400 rank range
      
        # OldTimer + Bad 501-600
        if (500 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 600) then
          
          # These are surveys that were good earlier but have fizzled to 0 < TCR < 0.05. The bad converters with TCR < 0.05 are also here. Ordered by Conversion. If their TCR becomes > 0.5 move them to Fast.
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then

            toberankedsurvey.SurveyGrossRank = 200 - (toberankedsurvey.TCR * 100)
            print "Assigned OldTimer survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          else
          end
            
            
          if (toberankedsurvey.CompletedBy.length == 0) then
            #Reposition according to latest Conversion
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              toberankedsurvey.SurveyGrossRank = 600
              print "OT/B: Repositioned: ", toberankedsurvey.SurveyGrossRank
              puts
              
            else
            
              toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
              print "OT/B: Repositioned: ", toberankedsurvey.SurveyGrossRank
              puts
              toberankedsurvey.label = 'OT/B: Repositioned'
            end
            
          else
          end
            
            
            
            
#         if (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.05) && (@toberankedsurveyNumberofAttemptsSinceLastComplete <= 20) then
            
#            toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.TCR * 100).to_i
#            print "Assigned Bad survey to Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#          else
#          end
          
          
  
 
#          if toberankedsurvey.CompletedBy.length > 0 then
      
#            toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length.to_f/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))     
      
#            if 0.02 <= toberankedsurvey.KEPC then   
        
              # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
#              if toberankedsurvey.KEPC * 100 >= 100 then
#                toberankedsurvey.SurveyGrossRank = 1
#                print "Assigned Bad toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              else
#                toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
#                print "Assigned Bad toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              end
        
#            else
#            end
      
#            if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    
    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
#              print "Assigned existing Bad toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end
      
#            if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then    
    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
#              print "Assigned existing Bad toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end 
      
#          else # for number of completes      
#          end # end for number of completes
    
        else # not in rank 501-600 range
        end # not in rank 501-600 range
  
        # Horrible : 601-700
        if (600 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 700) then
    
          # These are surveys which have seen moree than 20 attempts without a complete, if GCR>=0.01 or 10 attempts if GCR<0.01. Ordered by Conversion. If they do start converting then move them to appropriate buckets. Low CPI surveys that fizzle also land up here.
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then
            
            if toberankedsurvey.CPI > 1.49 then

              toberankedsurvey.SurveyGrossRank = 200 - (toberankedsurvey.TCR * 100).to_i
              print "Assigned Horrible survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>0.05 from H'
              
            else
              
              toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.TCR * 100).to_i
              print "Assigned Horrible survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'S: TCR>0.05 from H'
            end
              
          else
          end
            
          if ((toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.05)) then
            
            toberankedsurvey.SurveyGrossRank = 600 - (toberankedsurvey.TCR * 100)
            print "Assigned Horrible survey to OldTimers/Bad: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            toberankedsurvey.label = 'OT+B: TCR>0.05 from H'
          else
          end
          
          if (toberankedsurvey.CompletedBy.length == 0) then
            #Reposition according to latest Conversion
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              toberankedsurvey.SurveyGrossRank = 700
              
            else
            
              toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
              print "Updated existing Horrible survey rank to: ", toberankedsurvey.SurveyGrossRank
              puts
              toberankedsurvey.label = 'H: Repositioned'
            end
            
          else
          end
            
          
    
#          if toberankedsurvey.CompletedBy.length > 0 then
      
#            toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length.to_f/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))     
      
#            if 0.02 <= toberankedsurvey.KEPC then   
        
              # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
#              if toberankedsurvey.KEPC * 100 >= 100 then
#                toberankedsurvey.SurveyGrossRank = 1
#                print "Assigned Horrible toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              else
#                toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
#                print "Assigned Horrible toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#                puts
#              end
        
#            else
#            end
      
#            if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    
    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
#              print "Assigned existing Horrible toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end
      
#            if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then    
    
#              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#                p "Found a toberankedsurvey with Conversion = 0"
#                toberankedsurvey.Conversion = 1
#              else
#              end
      
#              toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
#              print "Assigned existing Horrible toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#              puts
#            end 
      
#          else # for number of completes    
      
#            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
#              p "Found a toberankedsurvey with Conversion = 0"
#              toberankedsurvey.Conversion = 1
#            else
#            end
    
#            toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
#            print "Assigned existing Horrible toberankedsurvey a Horrible tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
#            puts      
        
#          end # end for number of completes
    
        else # not in rank 601-700 range
        end # not in rank 601-700 range
                
        toberankedsurvey.save!

        print "Ranked survey number = ", toberankedsurvey.SurveyNumber
        puts
        
        end # do for all toberankedsurvey 
        
        
      else
        # i is not 1 and it has not been 20 mins since last ranking, so do nothing
      end # time for ranking
      
      print "******************** Last ranking time: ", @lastrankingtime
      puts
           

  end # do loop of totalavailablesurveys (i)
    
  # Delete surveys which are neither custom entered nor on the allocation list but are in local database
    
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
        end # if
        #         print 'looping list of allocationsurveys, count:', k
        #         puts
      end # do k
    end # do j
     
     print '******************** List of all surveys in DB', listofsurveynumbers
     puts
     print '****************** List of surveys not to be deleted', surveysnottobedeleted
     puts

     #   This section is there to remove old dead surveys.
    
     Survey.all.each do |oldsurvey| #do21
       if surveysnottobedeleted.include? (oldsurvey.SurveyNumber) then
         # do nothing
       else
         if oldsurvey.SurveySID == "DONOTDELETE" then
           # do nothing
         else
          surveystobedeleted << oldsurvey.SurveyNumber
          print '******************** DELETING THIS SURVEY NUMBER NOT on Allocation LIST nor marked DONOTDELETE ', oldsurvey.SurveyNumber
          puts
          oldsurvey.delete
        end
    end
  end # do21 oldsurvey
    
  print 'Surveys deleted: ', surveystobedeleted
  puts
    

  timenow = Time.now
  print 'Time at end', timenow
  puts
  if (timenow - starttime) > 1800 then 
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
      puts
      timetorepeat = true
    else
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to sleep for 5 minutes since it takes about 20 mins to do a sweep.'
      puts
      sleep (5.minutes)
      timetorepeat = true
    end

end while timetorepeat