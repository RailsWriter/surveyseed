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
@lastrankingtimeforpoorsurveys = Time.now


# Download the full allocations index

begin

  starttime = Time.now
  print '********************************At start at', starttime
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
  print '****************** Total allocated surveys: ', totalavailablesurveys+1
  puts


  # Check if any survey has allocation remaining, and get current qualifications and current quota.


  (0..totalavailablesurveys).each do |i|
    @surveynumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
    if (Survey.where("SurveyNumber = ?", @surveynumber)).exists? then 
      Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey|

        
        # Check if this exisitng survey has any remaining total allocation on the offerwall.

        # initialize failure count
        failcount1 = 0
        
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
          
          # increment failure count
          failcount1 = failcount1 + 1
          print "failcount1 =", failcount1
          puts
          
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
        end while ((@SupplierAllocations.code != 200) && (failcount1 < 10))
        
        
        # First check if there are any completes needed.
        
        survey.TotalRemaining = @SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]

        if ((@SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"] > 0) && (failcount1 < 10)) then
          
          print "********************* There is total remaining allocation for this EXISTING survey number: ", @surveynumber, ' in the amount of: ', @SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]
          puts
          

          # Update GEPC and Conversion information for the Existing survey. Ranking script every 20 mins will use the data to update ranks.
          
          
          # initialize failure count
          failcount3 = 0
          
          
          begin
            sleep(1)
            print '**************************** GETTING GLOBAL STATS (GEPC) for EXISTING survey: ', @surveynumber
            puts
        
            if flag == 'prod' then
              SurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+@surveynumber.to_s+'/5458/Global/Trailing?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                SurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+@surveynumber.to_s+'/5411/Global/Trailing?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
            
            # increment failure count
            failcount3 = failcount3 + 1
            print "failcount3 =", failcount3
            puts
            
            
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
          end while ((SurveyStatistics.code != 200) && (failcount3 < 10))
      

          if SurveyStatistics["SurveyStatistics"]["EffectiveEPC"] != nil then
            survey.GEPC = SurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
          else
            survey.GEPC = 0.0
          end
          
          survey.Conversion = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
                    
          print '******************* GEPC is: ', survey.GEPC, ' Conversion is: ', survey.Conversion
          puts 
 
 
 
      begin
        sleep(1)
        print '*************************** CONNECTING FOR QUALIFICATIONS INFORMATION on existing survey: ', @surveynumber
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
      survey.QualificationHHCPreCodes = ["ALL"]
      survey.QualificationEmploymentPreCodes = ["ALL"]      
      survey.QualificationPIndustryPreCodes = ["ALL"]
      survey.QualificationDMAPreCodes = ["ALL"]
      survey.QualificationStatePreCodes = ["ALL"]
      survey.QualificationDivisionPreCodes = ["ALL"]          
      survey.QualificationRegionPreCodes = ["ALL"]
      survey.QualificationJobTitlePreCodes = ["ALL"]

      survey.QualificationChildrenPreCodes = ["ALL"]
      survey.QualificationIndustriesPreCodes = ["ALL"]      
      


    # Update specific qualifications to be current information

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
        survey.QualificationEmploymentPreCodes = ["ALL"]      
        survey.QualificationPIndustryPreCodes = ["ALL"]
        survey.QualificationDMAPreCodes = ["ALL"]
        survey.QualificationStatePreCodes = ["ALL"]
        survey.QualificationDivisionPreCodes = ["ALL"]          
        survey.QualificationRegionPreCodes = ["ALL"]        
        survey.QualificationJobTitlePreCodes = ["ALL"]
        
        survey.QualificationChildrenPreCodes = ["ALL"]
        survey.QualificationIndustriesPreCodes = ["ALL"]
        
        
       
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
              if flag == 'stag' then
                print 'GENDER: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationGenderPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 45
              if flag == 'stag' then
#                print 'ZIP:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
#                puts
              else
              end
              survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
 


 
 
            when 12345
              #if flag == 'stag' then
                print '---------------------->> ZIP_Canada: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
                #else
                #end
              survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              
            when 1015
              #if flag == 'prod' then
                print '------------------->> Province/Territory_of_Canada: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
                #else
                #end
              # survey.QualificationCAProvincePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              survey.QualificationHHCPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              
            when 12340
              #if flag == 'prod' then
                print '----------------->> Fulcrum_ZIP_AU: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
                #else
                #end
              survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              
         
         
            when 12394
              #if flag == 'prod' then
                print '----------------->> Fulcrum_Region_AU_ISO: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
                #else
                #end
              #survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes") 
 
 
 

 
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
              survey.QualificationChildrenPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes") 
              
              
            when 643
              if flag == 'stag' then
                print '----------------------------------------------------------------->> STANDARD_INDUSTRY: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationIndustriesPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes") 
              
              
              
              



            when 2189
              if flag == 'stag' then
                print 'STANDARD_EMPLOYMENT: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationEmploymentPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")  

              



            when 5729
              if flag == 'stag' then
                print '************ STANDARD_INDUSTRY_PERSONAL: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end    
              survey.QualificationPIndustryPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              
            when 97
              if flag == 'stag' then
                print 'DMA: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationDMAPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              
            when 96
              if flag == 'stag' then
                print 'State: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationStatePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            
            when 101
              if flag == 'stag' then
                print 'Division: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationDivisionPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              
            when 122
              if flag == 'stag' then
                print 'Region: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationRegionPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")


            when 15294
              if flag == 'stag' then
                print '----------------------> JobTitle: ', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationJobTitlePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")

          end # case
          
        end #do j     
      end # if on Questions
  
      
    # Update Survey Quotas Information by SurveyNumber to current information
      
      
      begin
        sleep(1)
        print '******************************* GETTING QUOTA INFORMATION on existing survey: ', @surveynumber
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
        # This survey has no remaining allocation. It should be marked as if this survey is not alive. Consider removing this and just leaving totalremaining = 0
        survey.SurveyStillLive = false   
        
        survey.save!     
        
        print "********************* There is NO remaining allocation for this EXISTING survey number: ", @surveynumber
        puts
        
        end # end for total remaining in survey allocations 
      
      end # do the survey block
      
      else
        # Survey number does not exist. This is a NEW entry from allocation, get qualifications, quotas, and supplierlinks for it and create as new if the survey meets our biz requirements of countrylanguage, studytype, etc.        

 
        if (((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 5) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 6) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 9)) && ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 1) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 11) ||  (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 13) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 14) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 15) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 16) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 17) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 19) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 21) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 23))) then
      
          print '***************************** Biz Criteria match: CountryLanguageID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == nil ) ||      (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 5) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 6) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 9))
          puts

          print '***************************** Biz Criteria Match: StudyTypeID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 1) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 11) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 13) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 14) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 15) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 16) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 17) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 19) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 21) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 23))
puts
   
         print '***************************** Biz Criteria Match for SurveyNumber: ', @surveynumber
         puts
         print '***************************** Biz Criteria Match for StudyTypeID = ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"]
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
        
        # Also set SurveyExactRank, etc. to keep track of unsuccessful/OQ/success attempts.
        
        @newsurvey.FailureCount = 0
        @newsurvey.OverQuotaCount = 0
        # @newsurvey.KEPC = 0.0
        @newsurvey.NumberofAttemptsAtLastComplete = 0
        @newsurvey.TCR = 0.0
        @newsurvey.SurveyExactRank = 0
      
   
   
        # Code for testing
  
        @SurveyName = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyName"]
        SurveyNumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]   # same as @surveynumber
        
        print '**************************** PROCESSING i =', i
        puts
        print '**************************** SurveyName: ', @SurveyName, ' SurveyNumber: ', SurveyNumber, ' CountryLanguageID: ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"]
        puts
   

          # Before getting qualifications, quotas, and supplier links first check if there is any remaining total allocation for this NEW survey

          # initialize failure count
          failcount2 = 0
        
          begin
            sleep(1)
            puts '**************************** GETTING SUPPLIER ALLOCATIONS INFORMATION on NEW survey: ', SurveyNumber
            if flag == 'prod' then
              @NewSupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+SurveyNumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                @NewSupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end


            # increment failure count
            failcount2 = failcount2 + 1
            print "failcount2 =", failcount2
            puts
              
            rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
          end while ((@NewSupplierAllocations.code != 200) && (failcount2 < 10))

          if ((@NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"] > 0) && (failcount2 < 10)) then
          
            print '********************* There is total remaining allocation for this NEW survey number: ', SurveyNumber, ' in the amount of: ', @NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]
            puts
            
            @newsurvey.TotalRemaining = @NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]

        
      # Get Survey Qualifications Information by SurveyNumber
        
          begin
            sleep(2)
            puts 'GETTING QUALIFICATIONS INFORMATION of new survey'
 
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
          @newsurvey.QualificationHHCPreCodes = ["ALL"]
          @newsurvey.QualificationEmploymentPreCodes = ["ALL"]    
          @newsurvey.QualificationPIndustryPreCodes = ["ALL"]
          @newsurvey.QualificationDMAPreCodes = ["ALL"]
          @newsurvey.QualificationStatePreCodes = ["ALL"]
          @newsurvey.QualificationDivisionPreCodes = ["ALL"]          
          @newsurvey.QualificationRegionPreCodes = ["ALL"]
          @newsurvey.QualificationJobTitlePreCodes = ["ALL"]

          @newsurvey.QualificationChildrenPreCodes = ["ALL"]
          @newsurvey.QualificationIndustriesPreCodes = ["ALL"]
          
          
          
          # Insert specific qualifications where required

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
            @newsurvey.QualificationEmploymentPreCodes = ["ALL"]    
            @newsurvey.QualificationPIndustryPreCodes = ["ALL"]
            @newsurvey.QualificationDMAPreCodes = ["ALL"]
            @newsurvey.QualificationStatePreCodes = ["ALL"]
            @newsurvey.QualificationDivisionPreCodes = ["ALL"]          
            @newsurvey.QualificationRegionPreCodes = ["ALL"]
            @newsurvey.QualificationJobTitlePreCodes = ["ALL"]

            @newsurvey.QualificationChildrenPreCodes = ["ALL"]
            @newsurvey.QualificationIndustriesPreCodes = ["ALL"]
            
            
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
                  if flag == 'stag' then
                    print 'GENDER: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationGenderPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 45
                  if flag == 'stag' then
#                    print 'ZIP: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
#                    puts
                  else
                  end
                  @newsurvey.QualificationZIPPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                
                
                
                
                
                when 12345
                  if flag == 'stag' then
                    print '---------------------->> ZIP_Canada: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationZIPPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  
                when 1015
                  if flag == 'stag' then
                    print '------------------->> Province/Territory_of_Canada: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  # @@newsurvey.QualificationCAProvincePreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  @newsurvey.QualificationHHCPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  
                when 12340
                  if flag == 'stag' then
                    print '----------------->> Fulcrum_ZIP_AU: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationZIPPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  
             
             
                when 12394
                  if flag == 'stag' then
                    print '----------------->> Fulcrum_Region_AU_ISO: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  #@@newsurvey.QualificationZIPPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                
                
                
                
                
                
                
                
                
                
                
                
                
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
                    print '************* Age_and_Gender_of_Child: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationChildrenPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  
                  
                when 643
                  if flag == 'stag' then
                    print '----------------------------------------------------------------->> STANDARD_INDUSTRY: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationIndustriesPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes") 
                  
                  
                  
                  
                  
                  
                when 2189
                  if flag == 'stag' then
                    print '***************** STANDARD_EMPLOYMENT: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationEmploymentPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                   
                  
                  
                when 5729
                  if flag == 'stag' then
                    print '************ STANDARD_INDUSTRY_PERSONAL: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("LogicalOperator"), ' ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end    
                  @newsurvey.QualificationPIndustryPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                               
                when 97
                  if flag == 'stag' then
                    print '*********** DMA: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationDMAPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  
                when 96
                  if flag == 'stag' then
                    print '*************** State: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationStatePreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                
                when 101
                  if flag == 'stag' then
                    print '************* Division: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationDivisionPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  
                when 122
                  if flag == 'stag' then
                    print '*************** Region: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationRegionPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  
                when 15294
                  if flag == 'stag' then
                    print '-------------------> JobTitle: ', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationJobTitlePreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
          
                 
              end # case

            end #do15 for j      
          end # if SurveyQuals == nil
    
        
      # Get new Survey Quotas Information by SurveyNumber
        
          begin
            sleep(1)
            print '********************************** GETTING QUOTA INFORMATION for new survey: ', SurveyNumber
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

            # initialize failure count
            @newfailcount = 0
    
            begin
#            sleep(1)
              print '******************************** GETTING SupplierLinks for the new survey = ', SurveyNumber
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
              
              # increment failure count
              @newfailcount = @newfailcount+1
              print "newfailcount is: ", @newfailcount
              puts
            
              rescue HTTParty::Error => e
                puts 'HttParty::Error '+ e.message

            retry
            end while ((NewSupplierLink.code != 200) && (@newfailcount < 10))


            if NewSupplierLink.code != 200 then
              print '**************************************************** SUPPLIERLINKS NOT AVAILABLE'
              puts
              # Do not save this survey
            else  
              print '******************* SUPPLIERLINKS ARE AVAILABLE'
              puts
#             puts NewSupplierLink["SupplierLink"]["LiveLink"]
              @newsurvey.SupplierLink = NewSupplierLink["SupplierLink"]
              
              if NewSupplierLink["SupplierLink"]["CPI"] == nil then
                @newsurvey.CPI = 0.0
              else                
                @newsurvey.CPI = NewSupplierLink["SupplierLink"]["CPI"]   
              end
                           
           
              # Assign an initial gross rank to the NEW survey in 101-200 or 401-500 based on Conversion
        
              begin
                sleep(1)
                print '**************************** CONNECTING FOR GLOBAL STATS on NEW survey: ', SurveyNumber
                puts
          
                if flag == 'prod' then
                  NewSurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyStatistics/BySurveyNumber/'+SurveyNumber.to_s+'/5458/Global/Trailing?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
                else
                  if flag == 'stag' then
                    NewSurveyStatistics = HTTParty.get(base_url+'/Supply/v1/SurveyFStatistics/BySurveyNumber/'+SurveyNumber.to_s+'/5411/Global/Trailing?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
                  else
                  end
                end
                  rescue HTTParty::Error => e
                  puts 'HttParty::Error '+ e.message
                  retry
              end while NewSurveyStatistics.code != 200
        

              # For the NEW survey - save GEPC. It will be used to compute GCR.
        
              if NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] != nil then
                @newsurvey.GEPC = NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
              else
                @newsurvey.GEPC = 0.0
              end
                  
              
              # Assign a GCR to the new survey since we now have its CPI from SupplierLink
              
              if @newsurvey.CPI > 0 then
                @newGCR = @newsurvey.GEPC / @newsurvey.CPI
              else
                @newGCR = @newsurvey.GEPC
              end
              
               
               print '******************* GEPC for this new survey is = ', @newsurvey.GEPC, ' GCR is: ', @newGCR
               puts
              
               # Ranking by Conversion and GCR, if Conv=0
              
              if @newsurvey.Conversion > 0 then
          
                  @newsurvey.SurveyGrossRank = 101+(100-@newsurvey.Conversion)
                  print "Assigned Conv>0 survey rank: ", @newsurvey.SurveyGrossRank
                  puts
                  @newsurvey.label = 'N,C>0'
        
              else # Conv=0
        
                if (@newGCR >= 1) then
                  @newsurvey.SurveyGrossRank = 401
                  print "Assigned Conv=0 survey rank: ", @newsurvey.SurveyGrossRank, "GCR= ", @newGCR
                  puts
                  @newsurvey.label = 'N,C=0'
             
                else
            
                  @newsurvey.SurveyGrossRank = 500-(100*@newGCR)
                  print "Assigned Conv=0 survey rank: ", @newsurvey.SurveyGrossRank, "GCR= ", @newGCR
                  puts
                  @newsurvey.label = 'N,C=0'
                end

              end          
           
             
        # SAVE the new survey information in the database
              print '**************************************************** SAVING THE NEW SURVEY IN DATABASE'
              puts
             
              @newsurvey.save!
              
            end # SupplierLinks Available
 
          else # TotalNumberOfAllocations for the new survey
            
            # This NEW survey does not have any total remaining completes or the survey allocation call fails since the survey does not exit. It is like the survey is not live for us.
            # We may not save it locally. DO NOTHING.
            print "********************* There is NO remaining allocation for this NEW survey number: ", IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
            puts
            
          end # TotalNumberOfAllocations for the new survey
          
        else # download a new survey
          
            print '******************************** This survey does not meet our biz requirements: ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
            puts
            
            print '***************************** Biz Criteria Does NOT Match: CountryLanguageID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 5) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 6) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"] == 9))
            puts

            print '***************************** Biz Criteria Does NOT Match: StudyTypeID match is True or False: ', ((IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == nil ) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 1) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 11) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 13) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 14) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 15) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 16) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 17) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 19) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 21) || (IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"] == 23))
  
               puts
               
               print '***************************** Biz Criteria Does NOT Match:  StudyTypeID = ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["StudyTypeID"]
               puts
            
            
        end # download a new survey if the new survey qualifies for being suitable from countrylanguageID, studytypeID, and BidLOI criteria


      end # if @surveynumber exists  
      print '******************* Updating totalavailablesurveys at count i = ', i   
      puts
  
  
      # RANK the stack after every 60 minutes    
           
#      if (i == 30000) || ((Time.now - @lastrankingtime) >= 300000) then    
      
      if (i == 1) || ((Time.now - @lastrankingtime) >= 3600) then    
          
        @lastrankingtime = Time.now
        
        
        print "******************** Last ranking time for better surveys: ", @lastrankingtime
        puts        
        
      #  Survey.all.each do |toberankedsurvey|
        Survey.where("SurveyGrossRank < ?", 501).each do |toberankedsurvey|
    
          # Fast Converters 1-95
          if (0 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 95) then
    
            # Only TCR > 0.066 surveys in this group. Surveys arrive in TCR order. If they do not perform move them to Bad.

            if (toberankedsurvey.TotalRemaining == 0) || ((Time.now - toberankedsurvey.created_at > 86400*5) && (toberankedsurvey.TCR < 0.05)) then
    
              if toberankedsurvey.Conversion == 0 then
                toberankedsurvey.SurveyGrossRank = 800
                toberankedsurvey.label = 'D: Rem=0'
    
              else

                toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                print "Assigned 0 Remaining / Old to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'D: Rem=0'
              end
  
            else            
    
              @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
    
              if (@toberankedsurveyNumberofAttemptsSinceLastComplete > 15) then  # worst than 6.6% conversion rate i.e. 15 more after they were moved out of New or other ranks
      
                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                  toberankedsurvey.SurveyGrossRank = 600
                  toberankedsurvey.label = 'F->B'
      
                else
    
                  toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
                  print "Assigned Fast survey to Bad: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts
                  toberankedsurvey.TCR = 1.0 / @toberankedsurveyNumberofAttemptsSinceLastComplete
                  toberankedsurvey.label = 'F->B'
                end
      
              else
                
                if (toberankedsurvey.TCR == 1) then
                  toberankedsurvey.SurveyGrossRank = 1
                  print "Reposition Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts
                  toberankedsurvey.label = 'F->F'
                else
                  
                  toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.TCR * 100)
                  print "Reposition Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts
                  toberankedsurvey.label = 'F->F'
                  
                end
      
              end
      
            end # TotalRemaining
      
          else # not in 1-95 rank range
          end # not in 1-95 rank range      
          
          # Showcase 96-100
          if (95 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 100) then
            # do nothing. surveys are put here manually to give them quick exposure to traffic when network is ACTIVE or in SAFETY mode
          else
          end  # not in 96-100 range

          # Brand New+Conv>0 101-200        
          if (100 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 200) then
    
            # This is the place for brand new surveys to be tested with first 10 hits. They move to Fast or Try more if they do not complete in 10. If they changed to Conv=0 then move them to Conv=0
   
            if (toberankedsurvey.TotalRemaining == 0) || (Time.now - toberankedsurvey.created_at > 86400*5) then
      
              if toberankedsurvey.Conversion == 0 then
                toberankedsurvey.SurveyGrossRank = 800
                toberankedsurvey.label = 'D: Rem = 0'
      
              else

                toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                print "Assigned 0 Remaining / Old to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'D: Rem = 0'
              end
    
            else         
    
              if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.10) then # (1 in 10 hits)
                
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
                print "Assigned From Conv>0 to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'N->F'
      
              else # Completes > 0 or TCR >= 0.1
              end # Completes > 0 or TCR >= 0.1
    
              if (toberankedsurvey.CompletedBy.length == 0) then
      
                if toberankedsurvey.CPI > 0 then
                  @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
                else
                  @GCR = toberankedsurvey.GEPC
                end

                if (toberankedsurvey.Conversion == 0) then
            
                  if (@GCR >= 1) then
                    toberankedsurvey.SurveyGrossRank = 401
                    print "Assigned a Conv>0 N->P: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts 
                    toberankedsurvey.label = 'N->P'
       
                  else
        
                    toberankedsurvey.SurveyGrossRank = 500-(100*@GCR)
                    print "Assigned a Conv>0 N->P: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts    
                    toberankedsurvey.label = 'N->P'
                  end
                 
                else # Conversion>0

                    if (toberankedsurvey.SurveyExactRank > 10) then
                
                      if toberankedsurvey.Conversion == 0 then
                        toberankedsurvey.SurveyGrossRank = 400
                        print "Assigned Conv>0 to TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts 
                        toberankedsurvey.label = 'N->TM'
      
                      else

                        toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
                        print "Assigned Conv>0 to TM:", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts
                        toberankedsurvey.label = 'N->TM'
                      end
                        
                    else # less than 10 hits
            
                      # do nothing until it gets 10 hits, reposition within 101-200 on same day or move to 201-300 ranks if older than a day

                      if (Time.now - toberankedsurvey.created_at > 86400*1) then
                        if toberankedsurvey.Conversion == 0 then
                          toberankedsurvey.SurveyGrossRank = 300
                          print "Repositioned Conv>0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                          puts 
                          toberankedsurvey.label = 'N->G'
      
                        else

                          toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
                          print "Repositioned Conv>0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                          puts
                          toberankedsurvey.label = 'N->G'
                        end
                      
                      else  
                         
                        if toberankedsurvey.Conversion == 0 then
                          toberankedsurvey.SurveyGrossRank = 200
                          print "Repositioned Conv>0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                          puts 
                          toberankedsurvey.label = 'N->N'
      
                        else

                          toberankedsurvey.SurveyGrossRank = 101+(100-toberankedsurvey.Conversion)
                          print "Repositioned Conv>0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                          puts
                          toberankedsurvey.label = 'N->N'
                        end
                        
                      end # older than 24 hrs

                    end # more than 10 hits on a GCR>=0.01
 
                end # Conversion=0
        
              else # completes = 0
              end # completes = 0
              
            end  # TotalRemaining = 0

          else # not in 101-200 rank range
          end # not in 101-200 rank range

          # Good (Conv>0) 201-300
          if (200 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 300) then
    
            # This is the place for a day or older but good surveys to be tested with first 10 hits. They move to Fast or Try more if they do not complete in 10. If they changed to Conv=0 then move them to Conv=0
   
            if (toberankedsurvey.TotalRemaining == 0) || (Time.now - toberankedsurvey.created_at > 86400*5) then
      
              if toberankedsurvey.Conversion == 0 then
                toberankedsurvey.SurveyGrossRank = 800
                toberankedsurvey.label = 'D: Rem = 0'
      
              else

                toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                print "Assigned 0 Remaining / Old to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'D: Rem = 0'
              end
    
            else         
    
              if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.10) then # (1 in 10 hits)
      
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
                print "Assigned From Conv>0 to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'G->F'
      
              else # Completes > 0 or TCR >= 0.1
              end # Completes > 0 or TCR >= 0.1
    
              if (toberankedsurvey.CompletedBy.length == 0) then
      
                if toberankedsurvey.CPI > 0 then
                  @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
                else
                  @GCR = toberankedsurvey.GEPC
                end

                if (toberankedsurvey.Conversion == 0) then
            
                  if (@GCR >= 1) then
                    toberankedsurvey.SurveyGrossRank = 401
                    print "Assigned G->P: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts 
                    toberankedsurvey.label = 'G->P'
       
                  else
        
                    toberankedsurvey.SurveyGrossRank = 500-(100*@GCR)
                    print "Assigned a Conv>0 to Poor: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts    
                    toberankedsurvey.label = 'G->P'
                  end
                  
                else # Conversion>0

                    if (toberankedsurvey.SurveyExactRank > 10) then
                
                      if toberankedsurvey.Conversion == 0 then
                        toberankedsurvey.SurveyGrossRank = 400
                        print "Assigned Conv>0 to TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts 
                        toberankedsurvey.label = 'G->TM'
      
                      else

                        toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
                        print "Assigned Conv>0 to TM:", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts
                        toberankedsurvey.label = 'G->TM'
                      end
                
        
                    else # less than 10 hits
            
                      # do nothing until it gets 10 hits, reposition within 201-300
                         
                      if toberankedsurvey.Conversion == 0 then
                        toberankedsurvey.SurveyGrossRank = 300
                        print "Repositioned Conv>0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts 
                        toberankedsurvey.label = 'G->G'
      
                      else

                        toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
                        print "Repositioned Conv>0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts
                        toberankedsurvey.label = 'G->G'
                      end

                    end # more than 10 hits on a GCR>=0.01
 
                end # Conversion=0
        
              else # completes = 0
              end # completes = 0
              
            end  # TotalRemaining = 0

          else # not in 201-300 rank range
          end # not in 201-300 rank range

          # Try More 301-400
          if (300 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 400) then
    
            # These surveys are here to get another 5 attempts (10 to 15). If they convert move them to Fast else take them to Horrible        
    
            if (toberankedsurvey.TotalRemaining == 0) || (Time.now - toberankedsurvey.created_at > 86400*5) then
      
              if toberankedsurvey.Conversion == 0 then
                toberankedsurvey.SurveyGrossRank = 800
                toberankedsurvey.label = 'D: Rem = 0'
      
              else

                toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                print "Assigned 0 Remaining / Old to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'D: Rem = 0'
              end
    
            else                            
      
              if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.066) then
      
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
                print "Assigned Try more survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'TM->F'
      
              else # Completes > 0 or TCR >= 0.066
              end # Completes > 0 or TCR >= 0.066
    
              if (toberankedsurvey.CompletedBy.length == 0) then
      
      
                if toberankedsurvey.CPI > 0 then
                  @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
                else
                  @GCR = toberankedsurvey.GEPC
                end
                    
                if toberankedsurvey.SurveyExactRank <= 15 then # No. of hits
  
                  # do nothing - let it get 15 hits. Reposition for updated Conversion
       
                  if (toberankedsurvey.Conversion > 0) then

                      toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
                      print "Repositioned TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                      puts
                      toberankedsurvey.label = 'TM->TM'
          
                  else # Conversion changed to = 0
                        
                    if (@GCR >= 1) then
                      toberankedsurvey.SurveyGrossRank = 401
                      print "Assigned a TM to Conv=0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                      puts 
                      toberankedsurvey.label = 'TM->P'
       
                    else
        
                      toberankedsurvey.SurveyGrossRank = 500-(100*@GCR)
                      print "Assigned a TM to Conv=0: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                      puts    
                      toberankedsurvey.label = 'TM->P'
              
                    end
              
                 end # Conversion values 
          
                else # No. of hits > 15
  
                  if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                    p "Found a toberankedsurvey with Conversion = 0"
                    toberankedsurvey.SurveyGrossRank = 700
                    toberankedsurvey.label = 'H: Hits>15, TCR=0'
          
                  else

                    toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
                    print "Assigned a Try More to Horrible: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts   
                    toberankedsurvey.label = 'H: Hits>15, TCR=0'
                  end
    
                end # No. of hits
    
              else # number of completes = 0
              end # number of completes = 0
     
            end  # TotalRemaining 
          
          else
          end # not in rank 301-400 range
          
          # Poor (New+Conv=0) 401-500
          if (400 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 500) then
  
            # This is the place for new Conv=0 (Poor) surveys. If they make TCR>0.066 then move to Fast or Safety. Move to Bad if TCR<0.066 but more than 0. They move to Horrible if they do not complete in 10. If they turn GCR>=0.01 then move them to GCR>=0.01.    
    
            if (toberankedsurvey.TotalRemaining == 0) || (Time.now - toberankedsurvey.created_at > 86400*5) then
      
              if toberankedsurvey.Conversion == 0 then
                toberankedsurvey.SurveyGrossRank = 800
                toberankedsurvey.label = 'D: Rem = 0'
      
              else

                toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                print "Assigned 0 Remaining / Old to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'D: Rem = 0'
              end
    
            else              
    
              if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.066) then # (1 in 10 hits)
    
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
                print "Assigned Poor survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'P->F'
      
              else # Completes > 0 or TCR >= 0.066
              end # Completes > 0 or TCR >= 0.066
    
              if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.066) then
      
                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                  toberankedsurvey.SurveyGrossRank = 600
                  toberankedsurvey.label = 'P->B'
      
                else

                  toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
                  print "Assigned New/GCR<0.01 survey rank to OldTimers+Bad: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts    
                  toberankedsurvey.label = 'P->B'
                end
      
              else
              end  # Completes > 0 or 0 < TCR >= 0.066
  
              if (toberankedsurvey.CompletedBy.length == 0) then
      
                if toberankedsurvey.CPI > 0 then
                  @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
                else
                  @GCR = toberankedsurvey.GEPC
                end
    
                if (toberankedsurvey.Conversion > 0) then

                  toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
                  print "Conv>0: Conv changed,  From P: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts    
                  toberankedsurvey.label = 'P->G'
      
                else # (Conversion=0)

                    if (toberankedsurvey.SurveyExactRank > 10) then
      
                      toberankedsurvey.SurveyGrossRank = 700
                      print "Assigned New/GCR<0.01 survey rank to Horrible: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                      puts
                      toberankedsurvey.label = 'P->H'
 
                    else
          
                      # wait until there are 10 attempts, Reposition within 401-500 block                
                
                      if (@GCR >= 1) then
                        toberankedsurvey.SurveyGrossRank = 401
                        print "Repositioned Poor: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts 
                        toberankedsurvey.label = 'P->P'
       
                      else
        
                        toberankedsurvey.SurveyGrossRank = 500-(100*@GCR)
                        print "Poor: Repositioned: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                        puts    
                        toberankedsurvey.label = 'P->P'
              
                      end
             
                    end # more than 10 hits
      
                end # Conv >0
      
              else # completes = 0
              end # completes = 0
   
            end  # TotalRemaining
    
          else
          end # not in 401-500 rank range

        toberankedsurvey.save!

        print "Ranked survey number = ", toberankedsurvey.SurveyNumber
        puts
        
        end # do for all toberankedsurvey 
      else
        # i is not 1 and it has not been 30 mins since last ranking, so do nothing
      end # time for ranking
      
      print "******************** Last ranking time for better surveys: ", @lastrankingtime
      puts
      
      if ((Time.now - @lastrankingtimeforpoorsurveys) >= 9600) then    

        @lastrankingtimeforpoorsurveys = Time.now
        
        print "******************** Last ranking time for POOR surveys: ", @lastrankingtimeforpoorsurveys
        puts  
        
        Survey.where("SurveyGrossRank > ?", 500).each do |toberankedsurvey|

          
          # Bad 501-600
          if (500 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 600) then
    
            # These are surveys that were good earlier but have fizzled to 0 < TCR < 0.066. The bad converters with TCR < 0.066 are also here. Ordered by Conversion. If their TCR becomes > 0.066 move them to Fast.
    
            if (toberankedsurvey.TotalRemaining == 0) || (Time.now - toberankedsurvey.created_at > 86400*5) then
      
                if toberankedsurvey.Conversion == 0 then
                  toberankedsurvey.SurveyGrossRank = 800
                  toberankedsurvey.label = 'D: Rem = 0'
      
                else

                  toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                  print "Assigned 0 Remaining / Old to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts
                  toberankedsurvey.label = 'D: Rem = 0'
                end
    
            else
    
              if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.066) then

                toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
                print "Assigned OldTimer survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'F: TCR>0.066 in B'
              else
              end     
      
              if (toberankedsurvey.CompletedBy.length == 0) then
                # Reposition according to latest Conversion
      
                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                  toberankedsurvey.SurveyGrossRank = 600
                  print "B: Repositioned: ", toberankedsurvey.SurveyGrossRank
                  puts
                  toberankedsurvey.label = 'B->B'
        
                else
      
                  toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
                  print "B: Repositioned: ", toberankedsurvey.SurveyGrossRank
                  puts
                  toberankedsurvey.label = 'B->B'
                end
      
              else
              end
    
            end  # TotalRemaining

          else # not in rank 501-600 range
          end # not in rank 501-600 range

          # Horrible 601-700
          if (600 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 700) then

             # These are surveys which have seen moree than 15 attempts without a complete, if GCR>=0.01 or 10 attempts if GCR<0.01. Ordered by Conversion. If they do start converting then move them to appropriate buckets. Low CPI surveys that fizzle also land up here.
    
            if (toberankedsurvey.TotalRemaining == 0) || (Time.now - toberankedsurvey.created_at > 86400*5) then
      
              if toberankedsurvey.Conversion == 0 then
                toberankedsurvey.SurveyGrossRank = 800
                toberankedsurvey.label = 'D: Rem = 0'
      
              else

                toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                print "Assigned 0-Remaining / Old to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts
                toberankedsurvey.label = 'D: Rem = 0'
              end
    
            else          

              if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.066) then
      
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100).to_i
                print "Assigned Horrible survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'H->F: TCR>0.066'
        
              else
              end
      
              if ((toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.066)) then
      
                toberankedsurvey.SurveyGrossRank = 600 - (toberankedsurvey.TCR * 100)
                print "Assigned Horrible survey to Bad: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'H->B: TCR>0.066'
              else
              end
    
              if (toberankedsurvey.CompletedBy.length == 0) then
                # Reposition according to latest Conversion
      
                if toberankedsurvey.CPI > 0 then
                  @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
                else
                  @GCR = toberankedsurvey.GEPC
                end
               
                @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
      
                if (toberankedsurvey.Conversion > 0) && (@toberankedsurveyNumberofAttemptsSinceLastComplete < 15) then
          
                  toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
                  print "TM: From H: ", toberankedsurvey.SurveyGrossRank
                  puts
                  toberankedsurvey.label = 'H->TM'
         
                else     
      
                  if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                    toberankedsurvey.SurveyGrossRank = 700
                    toberankedsurvey.label = 'H->H'
        
                  else
      
                    toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
                    print "Updated existing Horrible survey rank to: ", toberankedsurvey.SurveyGrossRank
                    puts
                    toberankedsurvey.label = 'H->H'
                  end
      
                end # Conv, ALC conditions
      
              else
              end # no of completes = 0
     
            end  # TotalRemaining      

          else # not in rank 601-700 range
          end # not in rank 601-700 range
  
          # Dead 701-800
          if (700 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 800) then
    
            if (toberankedsurvey.TotalRemaining == 0) || (Time.now - toberankedsurvey.created_at > 86400*5) then
      
              # do nothing about it - stays dead
    
            else
          
                if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.066) then

                  toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
                  print "Assigned Dead survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  toberankedsurvey.label = 'D->F'
        
                else 
                end # Complete>0 & TCR >= 0.066
      
                if ((toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.066)) then
            
                  if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                    toberankedsurvey.SurveyGrossRank = 600
                    print "Dead survey to Bad: ", toberankedsurvey.SurveyGrossRank
                    puts
                    toberankedsurvey.label = 'D->B'
            
                  else
            
                    toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
                    print "Dead survey to Bad: ", toberankedsurvey.SurveyGrossRank
                    puts
                    toberankedsurvey.label = 'D->B'
              
                  end
          
                else
       
                end # Complete>0 & 0 < TCR >= 0.066
    
                if (toberankedsurvey.CompletedBy.length == 0) then
                  # Reposition according to latest Conversion
      
                  if toberankedsurvey.CPI > 0 then
                    @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
                  else
                    @GCR = toberankedsurvey.GEPC
                  end
               
                  @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
              
              
                  if (toberankedsurvey.Conversion > 0) && (@toberankedsurveyNumberofAttemptsSinceLastComplete < 15) then
          
                    toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
                    print "TM: From D: ", toberankedsurvey.SurveyGrossRank
                    puts
                    toberankedsurvey.label = 'D->TM'
     
                  else     
      
                    if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                      toberankedsurvey.SurveyGrossRank = 800
                      toberankedsurvey.label = 'D->D'
        
                    else
      
                      toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                      print "Updated existing Horrible survey rank to: ", toberankedsurvey.SurveyGrossRank
                      puts
                      toberankedsurvey.label = 'D->D'
                
                    end
      
                  end # Conv, ALC conditions
      
                else
                end # no of completes = 0
      
            end
    
          else
          end # not in Dead range 701-800
  
           # Ignore 801-900
          if (800 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 900) then
            # do nothing. surveys are put here manually to hide them from ranking
          else
          end  # not in 801-900 range
                  
        toberankedsurvey.save!

        print "Ranked survey number = ", toberankedsurvey.SurveyNumber
        puts
        
        end # do for all toberankedsurvey 
      
      else
        # i is not 1 and it has not been 60 mins since last ranking, so do nothing
      end # time for ranking
      
      print "******************** Last ranking time for POOR surveys: ", @lastrankingtimeforpoorsurveys
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
  end # do oldsurvey
     
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