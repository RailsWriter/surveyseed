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
          puts '**************************** CONNECTING FOR SUPPLIER ALLOCATIONS INFORMATION of an EXISTING survey: ', @surveynumber
          if flag == 'prod' then
            SupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+@surveynumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
          else
            if flag == 'stag' then
              SupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+@surveynumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
            else
            end
          end
            rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
        end while SupplierAllocations.code != 200

        if SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"] > 0 then
          
          print "********************* There is total remaining allocation for this EXISTING survey number: ", @surveynumber, ' in the amount of: ', SupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]
          puts


      begin
        sleep(1)
        puts 'CONNECTING FOR QUALIFICATIONS INFORMATION on existing survey: ', @surveynumber
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
          
      # Update specific qualifications to current information

        if SurveyQualifications["SurveyQualification"]["Questions"] == nil then
#      if SurveyQualifications["SurveyQualification"]["Questions"].empty? then
        puts 'SurveyQualifications or Questions is NIL'
        survey.QualificationAgePreCodes = ["ALL"]
        survey.QualificationGenderPreCodes = ["ALL"]
        survey.QualificationZIPPreCodes = ["ALL"]  
      else
        NumberOfQualificationsQuestions = SurveyQualifications["SurveyQualification"]["Questions"].length-1
        print 'NumberOfQualificationsQuestions: ', NumberOfQualificationsQuestions+1
        puts
            
        (0..NumberOfQualificationsQuestions).each do |j|
          # Survey.Questions = SurveyQualifications["SurveyQualification"]["Questions"]
 #        puts SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
        
          case SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
            when 42
              if flag == 'stag' then
                print 'Age:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                puts
              else
              end
              survey.QualificationAgePreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 43
              print 'Gender:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              puts
              survey.QualificationGenderPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
            when 45
              if flag == 'stag' then
#                print 'ZIPS:', SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
#                puts
              else
              end
              survey.QualificationZIPPreCodes = SurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
          end # case
        end #do j     
      end # if on Questions
 
 
      # Update Survey Quotas Information by SurveyNumber to current information
      begin
        sleep(1)
        puts 'CONNECTING FOR QUOTA INFORMATION on existing survey: ', @surveynumber
          
        if flag == 'prod' then
          SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
        else
          if flag == 'stag' then
            SurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
          else
          end
        end
            
          rescue HTTParty::Error => e
          puts 'HttParty::Error '+ e.message
          retry
        end while SurveyQuotas.code != 200

        # Save quotas information for each survey
  
#       if SurveyQuotas["SurveyStillLive"] == false then
#          puts '**************************** Deleting a closed survey'
#          survey.delete
#        else
          survey.SurveyStillLive = SurveyQuotas["SurveyStillLive"]
          survey.SurveyStatusCode = SurveyQuotas["SurveyStatusCode"]
          survey.SurveyQuotas = SurveyQuotas["SurveyQuotas"]
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
  
        SurveyName = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyName"]
        SurveyNumber = IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
        print 'PROCESSING i =', i
        puts
        print 'SurveyName: ', SurveyName, ' SurveyNumber: ', SurveyNumber, ' CountryLanguageID: ', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["CountryLanguageID"]
        puts
   
        # Assign an initial gross rank to the NEW survey
        # 10 is worst for the lowest conversion rate
        
        begin
          sleep(1)
          puts '**************************** CONNECTING FOR GLOBAL STATS on NEW survey: ', SurveyNumber
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
        

        if NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] > 0.2 then
          @newsurvey.SurveyGrossRank = 1
          print '******************* Effective GlobalEPC is > 0.2 = ', NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
          puts
        else
          if ((0 < NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]) && (NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"] <= 0.2)) then
            @newsurvey.SurveyGrossRank = 2
            print '******************* Effective GlobalEPC is <= 0.2 = ', NewSurveyStatistics["SurveyStatistics"]["EffectiveEPC"]
            puts
          else
          
            case IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["Conversion"]
              when 0..4
                puts "Lowest Rank 10"
                @newsurvey.SurveyGrossRank = 10
              when 5..9
                puts "Rank 9"
                @newsurvey.SurveyGrossRank = 9
              when 10..14
                puts "Rank 8"
                @newsurvey.SurveyGrossRank = 8
              when 15..19
                puts "Rank 7"
                @newsurvey.SurveyGrossRank = 7
              when 20..24
                puts "Rank 6"
                @newsurvey.SurveyGrossRank = 6
              when 25..29
                puts "Rank 5"
                @newsurvey.SurveyGrossRank = 5
              when 30..34
                puts "Rank 4"
                @newsurvey.SurveyGrossRank = 4
              when 35..39
                puts "Rank 3"
                @newsurvey.SurveyGrossRank = 3
              when 40..44
                puts "Rank 2"
                @newsurvey.SurveyGrossRank = 2
              when 45..100
                puts "Highest Rank 1"
                @newsurvey.SurveyGrossRank = 1
            end
          end
        end


          # Before getting qualifications, quotas, and supplier links first check if there is any remaining total allocation for this NEW survey
        
          begin
            sleep(1)
            puts '**************************** CONNECTING FOR SUPPLIER ALLOCATIONS INFORMATION on NEW survey: ', SurveyNumber
            if flag == 'prod' then
              NewSupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+SurveyNumber.to_s+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                NewSupplierAllocations = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/BySurveyNumber/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
          end while NewSupplierAllocations.code != 200

          if NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"] > 0 then
          
            print '********************* There is total remaining allocation for this NEW survey number: ', SurveyNumber, ' in the amount of: ', NewSupplierAllocations["SupplierAllocationSurvey"]["OfferwallTotalRemaining"]
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

          # Insert specific qualifications where required

          if NewSurveyQualifications["SurveyQualification"]["Questions"] == nil then
#          if NewSurveyQualifications["SurveyQualification"]["Questions"].empty? then
            puts 'SurveyQualifications or Questions is NIL'
            @newsurvey.QualificationAgePreCodes = ["ALL"]
            @newsurvey.QualificationGenderPreCodes = ["ALL"]
            @newsurvey.QualificationZIPPreCodes = ["ALL"]  
          else
            NumberOfQualificationsQuestions = NewSurveyQualifications["SurveyQualification"]["Questions"].length-1
            print 'NumberOfQualificationsQuestions: ', NumberOfQualificationsQuestions+1
            puts
    
            (0..NumberOfQualificationsQuestions).each do |j|
              # Survey.Questions = NewSurveyQualifications["SurveyQualification"]["Questions"]
 #             puts NewSurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
              case NewSurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
                when 42
                  if flag == 'stag' then
                    print 'Age:', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                    puts
                  else
                  end
                  @newsurvey.QualificationAgePreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 43
                  print 'Gender:', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                  puts
                  @newsurvey.QualificationGenderPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
                when 45
                  if flag == 'stag' then
#                    print 'ZIPS:', NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
#                    puts
                  else
                  end
                  @newsurvey.QualificationZIPPreCodes = NewSurveyQualifications["SurveyQualification"]["Questions"][j].values_at("PreCodes")
              end # case
            end #do      
          end # if
    
          # Get new Survey Quotas Information by SurveyNumber
          begin
            sleep(1)
            puts 'CONNECTING FOR QUOTA INFORMATION for new survey: ', SurveyNumber
          
            if flag == 'prod' then
              NewSurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
            else
              if flag == 'stag' then
                NewSurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
              else
              end
            end
          
              rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
              retry
            end while NewSurveyQuotas.code != 200

            # Save quotas information for each survey

#           if NewSurveyQuotas["SurveyStillLive"] == false then
#              @survey.delete
#            else
              @newsurvey.SurveyStillLive = NewSurveyQuotas["SurveyStillLive"]
              @newsurvey.SurveyStatusCode = NewSurveyQuotas["SurveyStatusCode"]
              @newsurvey.SurveyQuotas = NewSurveyQuotas["SurveyQuotas"]
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
            print '******************************** This survey does not meet our biz requirements', IndexofAllocatedSurveys["SupplierAllocationSurveys"][i]["SurveyNumber"]
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
    if (timenow - starttime) > 1200 then 
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
      puts
      timetorepeat = true
    else
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to sleep for 12 minutes'
      puts
      sleep (20.minutes)
 #     sleep (1800 - (timenow - starttime)).round
      timetorepeat = true
    end

end while timetorepeat