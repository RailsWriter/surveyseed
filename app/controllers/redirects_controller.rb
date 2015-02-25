class RedirectsController < ApplicationController
  def status
    
    require 'base64'
    require 'hmac-sha1'
    
    # Check if the response is valid by authenticating SHA-1 encrption
    @SHA1key = 'uhstarvsuio765jalksrWE'
    @Url = request.original_url
    @ParsedUrl = @Url.partition ("oenc=")
#    print '@BaseUrl=', @ParsedUrl[0]
#    puts 
#    print '@Signature =', @ParsedUrl[2]   
#    puts
    @BaseUrl = @ParsedUrl[0]
    @Signature = @ParsedUrl[2]
    @validateSHA1hash = Base64.encode64((HMAC::SHA1.new(@SHA1key) << @BaseUrl).digest).strip
#    p 'Validate 1 =', @validateSHA1hash  
    @validateSHA1hash = @validateSHA1hash.gsub '+', '-'
#    p 'Validate 2 =', @validateSHA1hash
    @validateSHA1hash = @validateSHA1hash.gsub '/', '_'
#    p 'Validate 3 =', @validateSHA1hash
    @validateSHA1hash= @validateSHA1hash.gsub '=', ''
#    p 'Validate 4 =', @validateSHA1hash
    
    @p2s_redirect = false # set to false as a flag. changes to true if it is a P2S redirect
    
    if (@validateSHA1hash != @Signature) then
      # invalid response, discard
      print '************ Redirects: Signature NOT verified, Validate 4 =', @validateSHA1hash
      puts
      if params[:PID] == 'test' then
        print '***************** PID = TEST found. Staging server does not generate Signatures '
        puts
      else
        if params[:PID][0..3] == "2215" then
          params[:PID] = params[:PID].sub "2215", ''
          
          print "********************* Extracted userid from P2S PID to be = ", params[:PID]
          puts
          
          @p2s_redirect = true
          
        else
          if params[:PID][0..3] == "1111" then
            @partial = params[:PID].sub "1111", ''
            params[:tsfn] = @partial[0..3]
            params[:PID] = @partial.sub params[:tsfn], ''
            params[:tis] = '20'
            
            print "********************* Extracted userid from KETSCI ADHOC survey to be = ", params[:PID], ' for Survey Number= ', params[:tsfn]
            puts

          else
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=0'
            return
          end
        end
      end
    else
      p '****************** Redirects: Signature verified **********************'
    end
    
    
    # SurveyExactRank is a counter for failures+OQ
    # SampleTypeID is used to count OQ incidences
    
    
    case params[:status] 
          
      when "1"
        # DefaultLink: https://www.ketsci.com/redirects/status?status=1&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'Redirected to Default'
        
        if params[:PID] == 'test' then 
          redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=1'
        else
          # save attempt info in User and Survey tables
          @user = User.find_by user_id: params[:PID]          
          
          print '*********** In *Default* for user_id: ', params[:PID], ' CID: ', @user.clickid
          puts
        
        # Is there anything to save from the attempt info in User and Survey tables?
        # params[:tsfn] was being returned empty in one run period.
        
        @user.SurveysAttempted << params[:tsfn]+'-1'
        @user.save
        
        # User lands up here if anything unclear happens in the ride. Best course seems to be to send the user back to very begining to start over.
        redirect_to 'https://www.ketsci.com/redirects/default'

#       Alternatively, we can automatically route the user - but it is risky as we do not exactly know the previos user state        
#        if (User.where("user_id = ?", params[:PID])).exists? then
#          @user = User.find_by user_id: params[:PID]
#          redirect_to 'https://www.ketsci.com/users/new'+'?NID='+@user.netid+'&CID='+@user.clickid
#        else
#          redirect_to 'https://www.ketsci.com/redirects/default'
#        end

        end


      when "2"
        # SuccessLink: https://www.ketsci.com/redirects/status?status=2&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]&cost=[%COST%]
        
        # save attempt info in User and Survey tables

        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=1'
        else  
          if @p2s_redirect then
            
            # save attempt info in User and Survey tables
          
            @user = User.find_by user_id: params[:PID]

            print '******************* Suceess in P2S router for user_id/PID: ', params[:PID], ' CID: ', @user.clickid
            puts

            @user.SurveysAttempted << 'P2S-2'
            # Save completed survey info in a hash with survey number as key {params[:tsfn] => [params[:cost], params[:tsfn]], ..}
            
            if @user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then 
              @net_name = "SuperSonic"
            else
            end
            
            if @user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then 
              @net_name = "Fyber"
            else
            end
            
            
            @user.SurveysCompleted[params[:PID]] = [Time.now, 'P2S', @user.clickid, @net_name]
            @user.save
            
            print "*************** User.netid is: ", @user.netid
            puts
              
            # Postback the network about success with users clickid
            if @user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then
                begin
                  @FyberPostBack = HTTParty.post('http://www2.balao.de/SPM4u?transaction_id='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                    rescue HTTParty::Error => e
                    puts 'HttParty::Error '+ e.message
                    retry
                end while @FyberPostBack.code != 200
            else
            end
            
            
            if @user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then
       
              begin
                @SupersonicPostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                  rescue HTTParty::Error => e
                  puts 'HttParty::Error '+ e.message
                  retry
              end while @SupersonicPostBack.code != 200
    
            else
            end
                     
            
            # Keep a count of completes on Supersonic Network
            
            puts "*************** Keeping track of cmpletes on SS network"
            
           
            if @user.netid = "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then
              @net = Network.find_by netid: @user.netid
              if @net.Flag3 == nil then
                @net.Flag3 = "1" 
              else
                @net.Flag3 = (@net.Flag3.to_i + 1).to_s
              end
            else
            end
            
            @net.save
                     
              
            # Happy ending
            redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=2'    
        
          else
          
            # save attempt info in User and Survey tables
          
            @user = User.find_by user_id: params[:PID]

            print '************** Suceess for user_id/PID: ', params[:PID], ' CID: ', @user.clickid
            puts
          
            @user.SurveysAttempted << params[:tsfn]+'-2'
            
            # Save completed survey info in a hash with survey number as key {params[:tsfn] => [params[:cost], params[:tsfn]], ..}
            
            if @user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then 
              @net_name = "SuperSonic"
            else
            end
            
            if @user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then 
              @net_name = "Fyber"
            else
            end
            
            
            @user.SurveysCompleted[params[:PID]] = [Time.now, params[:tsfn], @user.clickid, @net_name]
            @user.save
            
            

            @survey = Survey.find_by SurveyNumber: params[:tsfn]
            print '************ Successfully completed survey:', @survey.SurveyNumber #, 'by user_id:', @user.user_id
            puts
            # Save completed survey info in a hash with User_id number as key {params[:PID] => [params[:tis], params[:tsfn]], ..}
            @survey.CompletedBy[params[:PID]] = [Time.now, params[:tis], @user.clickid, @net_name]



            # Save (inverse of) TCR and reset counter for attempts at last complete

            @survey.SurveyExactRank = @survey.SurveyExactRank + 1  # SurveyExactRank=Failure+OQ+Success count
            @NumberofAttemptsSinceLastComplete = @survey.SurveyExactRank - @survey.NumberofAttemptsAtLastComplete
            @survey.TCR = (1.0 / @NumberofAttemptsSinceLastComplete).round(3)

            @survey.NumberofAttemptsAtLastComplete = @survey.SurveyExactRank
            
            # Move the just converted survey to F or S immediately, if it is already not there

            if (@survey.SurveyGrossRank > 200) then
              
              if (@survey.CPI > 1.49) then
      
                @survey.SurveyGrossRank = 201 - (@survey.TCR * 100)
                print "**************** Assigned just converted survey to Fast: ", @survey.SurveyGrossRank, ' Survey number = ', @survey.SurveyNumber
                @survey.label = 'F: Just converted'
      
              else
      
                  @survey.SurveyGrossRank = 101 - (@survey.TCR * 100)
                  print "************** Assigned Just converted to Safety: ", @survey.SurveyGrossRank, ' Survey number = ', @survey.SurveyNumber
                  @survey.label = 'S: Just converted'
        
              end 

            else

              # the survey is already in F or S i.e. rank is <= 200. do nothing

            end

            @survey.save

            # Postback the network about success with users clickid
            
            if @user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then
              begin
                @FyberPostBack = HTTParty.post('http://www2.balao.de/SPM4u?transaction_id='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                  rescue HTTParty::Error => e
                    puts 'HttParty::Error '+ e.message
                    retry
              end while @FyberPostBack.code != 200
            else
            end
            
            
            if @user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then
       
              begin
                @SupersonicPostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                  rescue HTTParty::Error => e
                  puts 'HttParty::Error '+ e.message
                  retry
              end while @SupersonicPostBack.code != 200
    
            else
            end
            
            
            
            # Keep a count of completes on Supersonic Network
            
            puts "*************** Keeping track of cmpletes on SS network"
            
           
            if @user.netid = "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then
              @net = Network.find_by netid: @user.netid
              if @net.Flag3 == nil then
                @net.Flag3 = "1" 
              else
                @net.Flag3 = (@net.Flag3.to_i + 1).to_s
              end
            else
            end
            
            @net.save
            
            
            
            
            

            # Happy ending
            redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=2'
          end
        end


      when "3"
        # FailureLink: https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        # FED uses this link is used when user is under age or they do not qualify for the survey they attempted. However since Ketsci eliminates those users already, this user
        # can be sent to try other surveys. If he/she has not qualified for any survey then take them to failure view.
      
        if params[:PID] == 'test' then 
          redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=2'
 
        else # if test
          
          if @p2s_redirect then
            
            # save attempt info in User and Survey tables
          
            @user = User.find_by user_id: params[:PID]

            print 'Failure in P2S router for user_id/PID, CID: ', params[:PID], @user.clickid
            puts

            @user.SurveysAttempted << 'P2S'+'-3'
            @user.save        
            
            #Tell user that they were not matched in P2S due to Failure
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=5'
            
          else # not p2s redirect
            
            # save attempt info in User and Survey tables
            @user = User.find_by user_id: params[:PID]          
          
            print 'Failure for user_id: ', params[:PID], ' CID: ', @user.clickid
            puts

            # Save last attempted survey unless user did not qualify for any (other) survey from start (no tsfn is attached)
            # This if may not be necessary now that users are stopped in the uer controller if they do not qualify.
            if params[:tsfn] != nil then
              @user.SurveysAttempted << params[:tsfn]+'-3'                   
              @user.save
            
            
              @survey = Survey.find_by SurveyNumber: params[:tsfn]
            
              # Increment unsuccessful attempts. SurveyExactRank is used to keep count of unsuccessful attempts on a survey
              @survey.SurveyExactRank = @survey.SurveyExactRank + 1
              @survey.FailureCount = @survey.FailureCount + 1
              print '********************************* Unsuccessful attempts count raised by 1 following a Failuare for survey number: ', params[:tsfn], ' new ExactRank (Failure+OQ+Success) count= ', @survey.SurveyExactRank
              puts
              
              @survey.save
            
            else # if params[tsfn] != nil
            end # if params[tsfn] != nil
            
            # Give user chance to take another survey unless they do not qualify for any (other) survey

            if (@user.SupplierLink.empty? == false) then
  
              if @user.country=="9" then 
                @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP='+@user.ZIP+'&HISPANIC='+@user.ethnicity+'&ETHNICITY='+@user.race+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_US='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
              else
                if @user.country=="6" then
                  @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP_Canada='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
                else
                  if @user.country=="5" then
                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_AU='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
                  else
                    if @user.country=="7" then
                      @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_IN='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
                    else
                      puts "*************************************** Redirects: Find out why country code is not correctly set"
                      @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
                      return
                    end
                  end
                end
              end
  
              @redirects_parsed_user_agent = UserAgent.parse(@user.user_agent)
    
              print "*************************************** Redirects: User platform is: ", @redirects_parsed_user_agent.platform
              puts
    
              if @redirects_parsed_user_agent.platform == 'iPhone' then
      
                @MS_is_mobile = '&MS_is_mobile=true'
                p "*************************************** Redirects: MS_is_mobile is set TRUE"
      
              else
                @MS_is_mobile = '&MS_is_mobile=false'
                p "*************************************** Redirects: MS_is_mobile is set FALSE"
      
              end


              if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                print 'User will be sent to this survey: ', @user.SupplierLink[0]
                puts
                @NextEntryLink = @user.SupplierLink[0]
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink
           
              else
                
                print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
                puts
                @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink

              end

            else # if SupplierLink empty?
              
              redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=3'
              
            end # if SupplierLink empty?
              
            
#            if (@survey.SurveyExactRank == 10 ) && (@survey.CompletedBy.length < 1) then
#              @survey.SurveyGrossRank = @survey.SurveyGrossRank + @survey.SurveyQuotaCalcTypeID
#              print '********************************* Reached 10 Unsuccessful attempts, and no completes - rank reduced proportionate to EEPC following a Failuare for survey number, to new rank: ', params[:tsfn], ' ', @survey.SurveyGrossRank
#              puts
#            else
#            end
            
#            if ( @survey.SurveyExactRank == 20 ) && (@survey.CompletedBy.length < 1) then
#              @survey.SurveyGrossRank = 21
#              print '********************************* Reached 20 Unsuccessful attempts, and no completes - rank reduced to 21 following a Failuare for survey number: ', params[:tsfn]
#              puts 
#            else
#            end            
            
#            if ( @survey.SurveyExactRank == 40 ) && (@survey.CompletedBy.length == 1) then
#              @survey.SurveyGrossRank = 21
#              print '********************************* Reached 100 Unsuccessful attempts, with only 1 complete - rank reduced to 21 following a Failuare for survey number: ', params[:tsfn]
#              puts 
#            else
#            end
            
#            if ( @survey.SurveyExactRank == 60 ) && (@survey.CompletedBy.length == 2) then
#              @survey.SurveyGrossRank = 21
#              print '********************************* Reached 60 Unsuccessful attempts, with only 2 complete - rank reduced to 21 following a Failuare for survey number: ', params[:tsfn]
#              puts 
#            else
#            end
            
#            if ( @survey.SurveyExactRank == 80 ) && (@survey.CompletedBy.length == 3) then
#              @survey.SurveyGrossRank = 21
#              print '********************************* Reached 80 Unsuccessful attempts, with only 3 complete - rank reduced to 21 following a Failuare for survey number: ', params[:tsfn]
#              puts 
#            else
#            end
            
#            if ( @survey.SurveyExactRank == 100 ) && (@survey.CompletedBy.length == 4) then
#              @survey.SurveyGrossRank = 21
#              print '********************************* Reached 100 Unsuccessful attempts, with only 4 complete - rank reduced to 21 following a Failuare for survey number: ', params[:tsfn]
#              puts 
#            else
#            end
            

#            if (( @survey.SurveyExactRank >= 120 ) && (( @survey.SurveyExactRank / (@survey.CompletedBy.length+0.1) ) > 10 ))
              # 0.1 is arbitrarily added to avoid division by 0
              
#              @survey.SurveyGrossRank = @survey.SurveyGrossRank + @survey.SurveyQuotaCalcTypeID
#              print '********************************* Reached 120+ Unsuccessful attempts, and less than 10% completes - rank reduced proportionate to EPC following a Failuare for survey number: ', params[:tsfn], ' to new rank: ', @survey.SurveyGrossRank
#              puts 
#            else
#            end
              
          
          end # p2s redirect   
        end # if test
                

      when "4"
        # OverQuotaLink: https://www.ketsci.com/redirects/status?status=4&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]

        # turn to t'test' be true on launch 
        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/overquota?&OQ=1'

        else # if test
          
          if @p2s_redirect then
            
            # save attempt info in User and Survey tables
          
            @user = User.find_by user_id: params[:PID]

            print 'OQ in P2S router for user_id/PID, CID: ', params[:PID], @user.clickid
            puts

            @user.SurveysAttempted << 'P2S'+'-4'
            @user.save  
            
            #Tell user that they were not matched due to OQ in P2S
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=6'

          else # not a p2sredirect
            
            # save attempt info in User and Survey tables
            @user = User.find_by user_id: params[:PID]


            print 'OQuota for user_id: ', params[:PID], ' CID: ', @user.clickid
            puts          
          
            @user.SurveysAttempted << params[:tsfn]+'-4'
            @user.save
          
          
            @survey = Survey.find_by SurveyNumber: params[:tsfn]
          
            # Increment unsuccessful attempts. SurveyExactRank is used to keep count of unsuccessful attempts on a survey

#            @survey.SampleTypeID = @survey.SampleTypeID + 1 # counts number of OQ incidents for a survey
            @survey.OverQuotaCount = @survey.OverQuotaCount + 1

            @survey.SurveyExactRank = @survey.SurveyExactRank + 1
            print '********************************* Unsuccessful attempts count raised by 1 following an OQ for survey number: ', params[:tsfn]
            puts
            
            @survey.save
            
            
            
          
#            if (@survey.SurveyExactRank == 10 ) && (@survey.CompletedBy.length < 1) then
#            @survey.SurveyGrossRank = @survey.SurveyGrossRank + @survey.SurveyQuotaCalcTypeID
#            print '********************************* Reached 10 Unsuccessful attempts, and no completes - rank reduced proportionate to EEPC following a OQ for survey number: ', params[:tsfn], ' to new rank: ', @survey.SurveyGrossRank
#            puts
#          else
#          end
          
#            if ( @survey.SurveyExactRank == 20 ) && (@survey.CompletedBy.length < 1) then
#            @survey.SurveyGrossRank = 21
#            print '********************************* Reached 20 Unsuccessful attempts, and no completes - rank reduced to 21 following a OQ for survey number: ', params[:tsfn]
#            puts 
#          else
#          end
          
#            if ( @survey.SurveyExactRank == 40 ) && (@survey.CompletedBy.length == 1) then
#            @survey.SurveyGrossRank = 21
#            print '********************************* Reached 40 Unsuccessful attempts, and 0nly 1 completes - rank reduced to 21 following a OQ for survey number: ', params[:tsfn]
#            puts 
#          else
#          end
          
#            if ( @survey.SurveyExactRank == 60 ) && (@survey.CompletedBy.length == 2) then
#            @survey.SurveyGrossRank = 20
#            print '********************************* Reached 60 Unsuccessful attempts, with only 2 completes - rank reduced to 21 following a OQ for survey number: ', params[:tsfn]
#            puts 
#          else
#          end
          
#            if ( @survey.SurveyExactRank == 80 ) && (@survey.CompletedBy.length == 3) then
#            @survey.SurveyGrossRank = 21
#            print '********************************* Reached 80 Unsuccessful attempts, with only 3 completes - rank reduced to 21 following a OQ for survey number: ', params[:tsfn]
#            puts 
#          else
#          end
          
#            if ( @survey.SurveyExactRank == 100 ) && (@survey.CompletedBy.length == 4) then
#            @survey.SurveyGrossRank = 21
#            print '********************************* Reached 100 Unsuccessful attempts, with only 4 completes - rank reduced to 21 following a OQ for survey number: ', params[:tsfn]
#            puts 
#          else
#          end
                   
#            if (( @survey.SurveyExactRank >= 120 ) && (( @survey.SurveyExactRank / (@survey.CompletedBy.length+0.1) ) > 10 ))
             # 0.1 is arbitrarily added to avoid division by 0
            
#            @survey.SurveyGrossRank = @survey.SurveyGrossRank + @survey.SurveyQuotaCalcTypeID
#            print '********************************* Reached 120+ Unsuccessful attempts, and less than 10% completes - rank reduced proportionate to EPC following a OQ for survey number: ', params[:tsfn], ' to new rank: ', @survey.SurveyGrossRank
#            puts 
#          else
#          end
                  
            
          

          # Give user chance to take another survey
          
          if (@user.SupplierLink.empty? == false) then
            
            
            if @user.country=="9" then 
              @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP='+@user.ZIP+'&HISPANIC='+@user.ethnicity+'&ETHNICITY='+@user.race+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_US='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
            else
              if @user.country=="6" then
                @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP_Canada='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
              else
                if @user.country=="5" then
                  @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_AU='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
                else
                  if @user.country=="7" then
                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_IN='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
                  else
                    puts "*************************************** Redirects: Find out why country code is not correctly set"
                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.householdcomp.to_s
                    return
                  end
                end
              end
            end



            @redirects_parsed_user_agent = UserAgent.parse(@user.user_agent)
    
            print "*************************************** UseRide: User platform is: ", @redirects_parsed_user_agent.platform
            puts
    
            if @redirects_parsed_user_agent.platform == 'iPhone' then
      
              @MS_is_mobile = '&MS_is_mobile=true'
              p "*************************************** UseRide: MS_is_mobile is set TRUE"
      
            else
              @MS_is_mobile = '&MS_is_mobile=false'
              p "*************************************** UseRide: MS_is_mobile is set FALSE"
      
            end

        
            if (@user.SupplierLink.length == 1) then #P2S is the next link
          
              print 'User will be sent to this survey: ', @user.SupplierLink[0]
              puts
              @NextEntryLink = @user.SupplierLink[0]
              @user.SupplierLink = @user.SupplierLink.drop(1)
              @user.save
              redirect_to @NextEntryLink
           
            else
        
              print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
              puts
              @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
              @user.SupplierLink = @user.SupplierLink.drop(1)
              @user.save
              redirect_to @NextEntryLink
            end
            
          else # if SupplierLink empty
            
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=4'
            
          end # if SupplierLink empty
          
          end # p2sredirect
        end # if test
              

      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'QTerm'
 
        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/qterm?&QTERM=1'
        else
                  
          # save attempt info in User and Survey tables
          @user = User.find_by user_id: params[:PID]
          
          print '*********************** QTerm for user_id/PID, CID:', params[:PID], @user.clickid
          puts     
        
          @user.SurveysAttempted << params[:tsfn]+'-5'
          @user.black_listed = true
          @user.save
          
          
          @survey = Survey.find_by SurveyNumber: params[:tsfn]
          
          # Increment unsuccessful attempts. SurveyExactRank is used to keep count of unsuccessful attempts on a survey

          @survey.SurveyExactRank = @survey.SurveyExactRank + 1
          print '***************************** Unsuccessful attempts count raised by 1 following a TERM for survey number: ', params[:tsfn]
          puts
            
          @survey.save
                    
          
          redirect_to 'https://www.ketsci.com/redirects/qterm?&QTERM=2'
        end
        
    end # case
  end # status
end # class