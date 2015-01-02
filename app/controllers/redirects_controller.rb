class RedirectsController < ApplicationController
  def status
    
    require 'base64'
    require 'hmac-sha1'
    
    # Check if the response is valid by authenticating SHA-1 encrption
    @SHA1key = 'uhstarvsuio765jalksrWE'
    @Url = request.original_url
    @ParsedUrl = @Url.partition ("oenc=")
    print '@BaseUrl=', @ParsedUrl[0]
    puts 
    print '@Signature =', @ParsedUrl[2]   
    puts
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
    
    if (@validateSHA1hash != @Signature) then
      # invalid response, discard
      print '************ Redirects: Signature NOT verified, Validate 4 =', @validateSHA1hash
      puts
      if params[:PID] == 'test' then
        print '***************** PID = TEST found. Staging server does not generate Signatures '
        puts
      else
        redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=1'
        return
      end
    else
      p '****************** Redirects: Signature verified'
    end
    
    case params[:status] 
      
      when "1"
        # DefaultLink: https://www.ketsci.com/redirects/status?status=1&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'Redirected to Default'
        
        # Is there anything to save from the attempt info in User and Survey tables?
        @user.SurveysAttempted << params[:tsfn]+'1111'
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

      when "2"
        # SuccessLink: https://www.ketsci.com/redirects/status?status=2&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]&cost=[%COST%]
        
        # save attempt info in User and Survey tables

#       Turn to 'test' be true on launch 
        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=1'
        else
          # save attempt info in User and Survey tables
          
         @user = User.find_by user_id: params[:PID]
#          @user = User.last

         print 'Suceess for user_id/PID, CID:', params[:PID], @user.clickid
         puts

#         In case user not found - should not happen since we sent the PID in the first place.
#          if (User.where("user_id = ?", params[:PID])).exists? then
#            @user = User.find_by user_id: params[:PID]
#          else
#            redirect_to 'https://www.ketsci.com/redirects/contactus'
#          end
          
          @user.SurveysAttempted << params[:tsfn]+'2222'
          # Save completed survey info in a hash with survey number as key {params[:tsfn] => [params[:cost], params[:tsfn]], ..}
          @user.SurveysCompleted[params[:tsfn]] = [params[:cost], params[:tsfn], @user.clickid, @user.netid]
          @user.save

          @survey = Survey.find_by SurveyNumber: params[:tsfn]
          print 'Successfully completed survey:', @survey.SurveyNumber #, 'by user_id:', @user.user_id
          puts
          # Save completed survey info in a hash with User_id number as key {params[:PID] => [params[:tis], params[:tsfn]], ..}
          @survey.CompletedBy[params[:PID]] = [params[:tis], params[:tsfn], @user.clickid, @user.netid]
          @survey.SurveyGrossRank = 1
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

# Give user a chance to take another survey
#         if (@user.SupplierLink) then
#          redirect_to @user.SupplierLink[0]+params[:PID]
#          else
#            redirect_to 'https://www.ketsci.com/redirects/failure?&SUCCESS=2'
#          end

          # Happy ending
          redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=2'
        end

      when "3"
        # FailureLink: https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        # FED uses this link is used when user is under age or they do not qualify for the survey they attempted. However since Ketsci eliminates those users already, this user
        # can be sent to try other surveys. If he/she has not qualified for any survey then take them to failure view.

# turn to 'test' be true on launch        
        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=2'
        else
          # save attempt info in User and Survey tables
          @user = User.find_by user_id: params[:PID]          
#          @user = User.last

          print 'Failure for user_id/PID, CID:', params[:PID], @user.clickid
          puts

          # Save last attempted survey unless user did not qualify for any (other) survey from start (no tsfn is attached)
          # This if may not be necessary now that users are stopped in the uer controller if they do not qualify.
          if params[:tsfn] != nil then
            @user.SurveysAttempted << params[:tsfn]+'3333'                   
            @user.save
          else
          end

          # Give user chance to take another survey unless they do not qualify for any (other) survey   
                 
#          if (@user.SupplierLink) then
#            redirect_to @user.SupplierLink[0]+params[:PID]

          if (@user.SupplierLink.empty? == false) then
  
            if @user.country=="9" then 
              @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP='+@user.ZIP
            else
              if @user.country=="6" then
                @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP_Canada='+@user.ZIP
              else
                if @user.country=="5" then
                  @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_AU='+@user.ZIP
                else
                  if @user.country=="7" then
                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_IN='+@user.ZIP
                  else
                    puts "*************************************** Redirects: Find out why country code is not correctly set"
                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender
                    return
                  end
                end
              end
            end
  
            print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
            puts
            @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
            @user.SupplierLink = @user.SupplierLink.drop(1)
            @user.save
            redirect_to @NextEntryLink

          else
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=3'
          end
        end
        
      when "4"
        # OverQuotaLink: https://www.ketsci.com/redirects/status?status=4&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]

# turn to t'test' be true on launch 
        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/overquota?&OQ=1'
        else
          # save attempt info in User and Survey tables
          @user = User.find_by user_id: params[:PID]
#          @user = User.last

          print 'OQuota for user_id/PID, CID:', params[:PID], @user.clickid
          puts          
          
          @user.SurveysAttempted << params[:tsfn]+'4444'
          @user.save

          # Give user chance to take another survey
          
          if (@user.SupplierLink.empty? == false) then
            
            if @user.country=="9" then 
              @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP='+@user.ZIP
            else
              if @user.country=="6" then
                @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP_Canada='+@user.ZIP
              else
                if @user.country=="5" then
                  @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_AU='+@user.ZIP
                else
                  if @user.country=="7" then
                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_IN='+@user.ZIP
                  else
                    puts "*************************************** Redirects: Find out why country code is not correctly set"
                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender
                    return
                  end
                end
              end
            end
            
            print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
            puts
            @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
            @user.SupplierLink = @user.SupplierLink.drop(1)
            @user.save
            redirect_to @NextEntryLink
          else
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=3'
          end
        end
    
      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'QTerm'

# turn to t'test' be true on launch 
        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/qterm?&QTERM=1'
        else
          # save attempt info in User and Survey tables
          @user = User.find_by user_id: params[:PID]
#          @user = User.last
          
          print 'QTerm for user_id/PID, CID:', params[:PID], @user.clickid
          puts     
        
          @user.SurveysAttempted << params[:tsfn]+'5555'
          @user.black_listed = true
          @user.save
          redirect_to 'https://www.ketsci.com/redirects/qterm?&QTERM=2'
        end
    end
  end
end