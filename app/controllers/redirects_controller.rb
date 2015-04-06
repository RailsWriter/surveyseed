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
    @rfg_redirect = false # set to false as a flag. changes to true if it is a RFG redirect
    
    if params[:PID] == nil then
      params[:PID] = "PlaceHolder"
    else
    end
    
    if (@validateSHA1hash != @Signature) then
      # invalid response, discard
      print '************ Redirects: Signature NOT verified, Validate 4 =', @validateSHA1hash
      puts
      if params[:PID] == 'test' then
        print '***************** PID = TEST found. Staging server does not generate Signatures '
        puts
      else
        if params[:PID][0..3] == "2222" then
          params[:PID] = params[:PID].sub "2222", ''
          
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
            
            if params[:rid][0..3] == "3333" then
              params[:PID] = params[:rid].sub "3333", ''
              params[:tsfn] = params[:rfg_id]
              params[:tis] = '20'
              print "********************* Extracted userid from RFG PID to be = ", params[:PID]
              puts
          
              @rfg_redirect = true
            else
              redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=0'
              return
            end
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

#       Fix this to route the user to take other surveys       
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
            
            if @user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then 
              @net_name = "Fyber"
            else
            end  
            
            if @user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then 
              @net_name = "SuperSonic"
            else
            end       
            
            if @user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then 
              @net_name = "RadiumOne"
            else
            end
            
            if @user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then 
              @net_name = "SS2"
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
                        
            
            if @user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then
     
             begin
               @RadiumOnePostBack = HTTParty.post('panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                 rescue HTTParty::Error => e
                puts 'HttParty::Error '+ e.message
                 retry
             end while @RadiumOnePostBack.code != 200
  
            else
            end
                        
            
            if @user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then
       
              begin
                @SS2PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                  rescue HTTParty::Error => e
                  puts 'HttParty::Error '+ e.message
                  retry
              end while @SS2PostBack.code != 200
    
            else
            end
                     
            
            # Keep a count of completes on Supersonic Network
            
            puts "*************** Keeping track of completes on SS network"
            
           
#            if @user.netid = "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then
            @net = Network.find_by netid: @user.netid
            
            if @net.Flag3 == nil then
              
              @net.Flag3 = "1" 
              @net.save
              
            else

              @net.Flag3 = (@net.Flag3.to_i + 1).to_s
              @net.save

            end
            
             
            # Happy ending
            redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=2'    
        
          else # not a P2S project
            
            if @rfg_redirect then
             
              # save attempt info in User and Survey tables
          
              @user = User.find_by user_id: params[:PID]

              print '************** Suceess for user_id/PID: ', params[:PID], ' CID: ', @user.clickid
              puts
          
              @user.SurveysAttempted << params[:tsfn]+'-2'
            
              # Save completed survey info in a hash with survey number as key {params[:tsfn] => [params[:cost], params[:tsfn]], ..}
            
            
              if @user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then 
                @net_name = "Fyber"
              else
              end
              
              if @user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then 
                @net_name = "SuperSonic"
              else
              end
              
              if @user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then 
                @net_name = "Fyber"
              else
              end
              
              if @user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then 
                @net_name = "SS2"
              else
              end
            
              @user.SurveysCompleted[params[:PID]] = [Time.now, params[:tsfn], 'RFG', @user.clickid, @net_name]
              @user.save
              
              
              @project = RfgProject.find_by rfg_id: params[:tsfn]
            
            
              if (@project == nil) then
                sleep(1)
                @project = RfgProject.find_by rfg_id: params[:tsfn]
                puts " *********** Retried retrieving project"
              else
              end    
                 
              print '************ Successfully completed project:', @project.rfg_id
              puts
              # Save completed project info in a hash with User_id number as key {params[:PID] => [params[:tis], params[:tsfn]], ..}
          
            
              @project.CompletedBy[params[:PID]] = [Time.now, params[:tis], @user.clickid, @net_name]
              @project.save

              # Save (inverse of) TCR and reset counter for attempts at last complete
            
        #      @survey.SurveyExactRank = @survey.SurveyExactRank + 1  # SurveyExactRank=Failure+OQ+Success count
        #      @NumberofAttemptsSinceLastComplete = @survey.SurveyExactRank - @survey.NumberofAttemptsAtLastComplete
        #      @survey.TCR = (1.0 / @NumberofAttemptsSinceLastComplete).round(3)

        #      @survey.NumberofAttemptsAtLastComplete = @survey.SurveyExactRank
            
              # Move the just converted survey to F or S immediately, if it is already not there
            
        #      if (@survey.SurveyGrossRank > 200) then
              
        #      if (@survey.CPI > 1.49) then
      
        #        @survey.SurveyGrossRank = 201 - (@survey.TCR * 100)
        #        print "**************** Assigned just converted survey to Fast: ", @survey.SurveyGrossRank, ' Survey number = ', @survey.SurveyNumber
        #        @survey.label = 'F: JUST CONVERTED'
      
        #      else
      
        #          @survey.SurveyGrossRank = 101 - (@survey.TCR * 100)
        #          print "************** Assigned Just converted to Safety: ", @survey.SurveyGrossRank, ' Survey number = ', @survey.SurveyNumber
        #          @survey.label = 'S: JUST CONVERTED'
        
        #      end 

        #    else

              # the survey is already in F or S i.e. rank is <= 200. do nothing

        #    end

        #      @survey.save

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
            
              if @user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then
     
                begin
                  @RadiumOnePostBack = HTTParty.post('panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                   rescue HTTParty::Error => e
                     puts 'HttParty::Error '+ e.message
                     retry
                  end while @RadiumOnePostBack.code != 200
  
              else
              end
              
              if @user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then
       
                begin
                  @SS2PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                    rescue HTTParty::Error => e
                    puts 'HttParty::Error '+ e.message
                    retry
                end while @SS2PostBack.code != 200
    
              else
              end                        
            
              # Keep a count of completes on all Networks
            
              puts "*************** Keeping track of completes on all networks"
            
              @net = Network.find_by netid: @user.netid
              if @net.Flag3 == nil then
              
              @net.Flag3 = "1" 
              @net.save
              
            else
              
              @net.Flag3 = (@net.Flag3.to_i + 1).to_s
              @net.save
              
            end
                     

              # Happy ending
              redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=2'
             
             
              
          
          
          
          
          
          
          
          
          
              
            else # not a RFG project. it must be a FED survey
            
          
              # save attempt info in User and Survey tables
          
              @user = User.find_by user_id: params[:PID]

              print '************** Suceess for user_id/PID: ', params[:PID], ' CID: ', @user.clickid
              puts
          
              @user.SurveysAttempted << params[:tsfn]+'-2'
            
              # Save completed survey info in a hash with survey number as key {params[:tsfn] => [params[:cost], params[:tsfn]], ..}
            
              if @user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then 
                @net_name = "Fyber"
              else
              end
                           
              if @user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then 
                @net_name = "SuperSonic"
              else
              end
            
              if @user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then 
                @net_name = "RadiumOne"
              else
              end
              
              if @user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then 
                @net_name = "SS2"
              else
              end
              
            
              @user.SurveysCompleted[params[:PID]] = [Time.now, params[:tsfn], @user.clickid, @net_name]
              @user.save
            

              @survey = Survey.find_by SurveyNumber: params[:tsfn]
            
            
 #             if (@survey == nil) then
#              sleep(1)
 #             @survey = Survey.find_by SurveyNumber: params[:tsfn]
#              puts " *********** Retried retrieving survey"
 #           else
  #          end    
        
              print '************ Successfully completed survey:', @survey.SurveyNumber
              puts
              # Save completed survey info in a hash with User_id number as key {params[:PID] => [params[:tis], params[:tsfn]], ..}
          
            
              @survey.CompletedBy[params[:PID]] = [Time.now, params[:tis], @user.clickid, @net_name]
              @survey.save!

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
                @survey.label = 'F: JUST CONVERTED'
      
              else
      
                  @survey.SurveyGrossRank = 101 - (@survey.TCR * 100)
                  print "************** Assigned Just converted to Safety: ", @survey.SurveyGrossRank, ' Survey number = ', @survey.SurveyNumber
                  @survey.label = 'S: JUST CONVERTED'
        
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
              
              if @user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then
     
                begin
                  @RadiumOnePostBack = HTTParty.post('panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                   rescue HTTParty::Error => e
                     puts 'HttParty::Error '+ e.message
                     retry
                  end while @RadiumOnePostBack.code != 200
  
              else
              end
              
              if @user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then
       
                begin
                  @SS2PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                    rescue HTTParty::Error => e
                    puts 'HttParty::Error '+ e.message
                    retry
                end while @SS2PostBack.code != 200
    
              else
              end
                       
              # Keep a count of completes on all Networks
            
              puts "*************** Keeping track of completes on all networks"
            
           
           
              @net = Network.find_by netid: @user.netid
              if @net.Flag3 == nil then
              
              @net.Flag3 = "1" 
              @net.save
              
            else
              
              @net.Flag3 = (@net.Flag3.to_i + 1).to_s
              @net.save
              
            end
                     

              # Happy ending
              redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=3'


            end # if RFG
          end # if P2S
        end # if test


      when "3"
        # FailureLink: https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        # FED uses this link when user is under age or they do not qualify for the survey they attempted. However since Ketsci eliminates those users already, this user
        # can be sent to try other surveys. If he/she has not qualified for any survey then take them to failure view.
      
        if params[:PID] == 'test' then 
          redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=2'
 
        else # if test
          
          if @p2s_redirect then
            
            # save attempt info in User and Survey tables
          
            @user = User.find_by user_id: params[:PID]

            print 'Status = Failure in P2S router for user_id/PID, CID: ', params[:PID], @user.clickid
            puts

            @user.SurveysAttempted << 'P2S'+'-3'
            @user.save        
            
            #Tell user that they were not matched in P2S due to Failure
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=5'
            
          else # not p2s redirect
                        
            if @rfg_redirect then
              
              # save attempt info in User and RfgOroject tables
              @user = User.find_by user_id: params[:PID]          
          
              print 'Status = RFG Failure for user_id: ', params[:PID], ' CID: ', @user.clickid
              puts

              # Save last attempted project unless user did not qualify for any (other) project from start (no tsfn is attached)
              # This may not be necessary now that users are stopped in the uer controller if they do not qualify.
              if params[:tsfn] != nil then
                @user.SurveysAttempted << params[:tsfn]+'-3'                   
                @user.save
            
            
#                @project = RfgProject.find_by rfg_id: params[:tsfn]
              
#                if (@project == nil) then
#                  sleep(1)
#                  @project = RfgProject.find_by rfg_id: params[:tsfn]
#                  puts " *********** Retried retrieving project"
                else
                end
                
            
                # Increment unsuccessful attempts. SurveyExactRank is used to keep count of unsuccessful attempts on a survey
#                @survey.SurveyExactRank = @survey.SurveyExactRank + 1
#                @survey.FailureCount = @survey.FailureCount + 1
#                print '********************************* Unsuccessful attempts count raised by 1 following a Failuare for survey number: ', params[:tsfn], ' new ExactRank (Failure+OQ+Success) count= ', @survey.SurveyExactRank
#                puts
              
#                @project.save
            
#              else # if params[tsfn] != nil
#              end # if params[tsfn] != nil
            
              # Give user chance to take another survey unless they do not qualify for any (other) survey

              if (@user.SupplierLink.empty? == false) then

#                if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                  print 'User will be sent to this survey: ', @user.SupplierLink[0]
                  puts
                  @NextEntryLink = @user.SupplierLink[0]
                  @user.SupplierLink = @user.SupplierLink.drop(1)
                  @user.save
                  redirect_to @NextEntryLink
           
#                else 
                
#                print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
#                  print 'User will be sent to this project: ', @user.SupplierLink[0]
#                  puts
#                  @NextEntryLink = @user.SupplierLink[0]
              #  @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
              #  @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
#                  @user.SupplierLink = @user.SupplierLink.drop(1)
#                  @user.save
#                  redirect_to @NextEntryLink

#                end

              else # if SupplierLink empty?
              
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=3'
              
              end # if SupplierLink empty?





              
            else # must be FED
            
            
              # save attempt info in User and Survey tables
              @user = User.find_by user_id: params[:PID]          
          
              print 'Status = Failure for user_id: ', params[:PID], ' CID: ', @user.clickid
              puts

              # Save last attempted survey unless user did not qualify for any (other) survey from start (no tsfn is attached)
              # This if may not be necessary now that users are stopped in the uer controller if they do not qualify.
              if params[:tsfn] != nil then
                @user.SurveysAttempted << params[:tsfn]+'-3'                   
                @user.save
            
            
                @survey = Survey.find_by SurveyNumber: params[:tsfn]
              
                if (@survey == nil) then
                  sleep(1)
                  @survey = Survey.find_by SurveyNumber: params[:tsfn]
                  puts " *********** Retried retrieving survey"
                else
                end
                
            
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
              
              
#              if @user.children != nil then
#                @childrenvalue = '&Age_and_Gender_of_Child='+@user.children[0]
#                if @user.children.length > 1 then
#                  (1..@user.children.length-1).each do |i|
#                    @childrenvalue = @childrenvalue+'&Age_and_Gender_of_Child='+@user.children[i]
#                  end
#                else
#                end
#              else
#              end
              
  
#              if @user.country=="9" then 
#                @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP='+@user.ZIP+'&HISPANIC='+@user.ethnicity+'&ETHNICITY='+@user.race+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_US='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#              else
#                if @user.country=="6" then
#                  @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP_Canada='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#                else
#                  if @user.country=="5" then
#                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_AU='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#                  else
#                    if @user.country=="7" then
#                      @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_IN='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#                    else
#                      puts "*************************************** Redirects: Find out why country code is not correctly set"
#                      @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#                      return
#                    end
#                  end
#                end
#              end
  
#              @redirects_parsed_user_agent = UserAgent.parse(@user.user_agent)
    
#              print "*************************************** Redirects: User platform is: ", @redirects_parsed_user_agent.platform
#              puts
    
#              if @redirects_parsed_user_agent.platform == 'iPhone' then
      
#                @MS_is_mobile = '&MS_is_mobile=true'
#                p "*************************************** Redirects: MS_is_mobile is set TRUE"
      
#              else
#                @MS_is_mobile = '&MS_is_mobile=false'
#                p "*************************************** Redirects: MS_is_mobile is set FALSE"
      
#              end


                if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                  print 'User will be sent to this survey: ', @user.SupplierLink[0]
                  puts
                  @NextEntryLink = @user.SupplierLink[0]
                  @user.SupplierLink = @user.SupplierLink.drop(1)
                  @user.save
                  redirect_to @NextEntryLink
           
                else
                
#                print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
                  print 'User will be sent to this survey: ', @user.SupplierLink[0]
                  puts
                  @NextEntryLink = @user.SupplierLink[0]
#                @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
              #  @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
                  @user.SupplierLink = @user.SupplierLink.drop(1)
                  @user.save
                  redirect_to @NextEntryLink

                end

              else # if SupplierLink empty?
              
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=4'
              
              end # if SupplierLink empty?
              
              
            end # if RFG          
          end # if p2s redirect   
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
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=5'

          else # not a p2sredirect
            
            if @rfg_redirect then
            
              # save attempt info in User and Survey tables
              @user = User.find_by user_id: params[:PID]


              print 'OQuota for user_id: ', params[:PID], ' CID: ', @user.clickid
              puts          
          
              @user.SurveysAttempted << params[:tsfn]+'-4'
              @user.save
          
          
#              @survey = Survey.find_by SurveyNumber: params[:tsfn]
            
#              if (@survey == nil) then
#                sleep(1)
#                @survey = Survey.find_by SurveyNumber: params[:tsfn]
#                puts " *********** Retried retrieving survey"
#              else
#              end    
          
              # Increment unsuccessful attempts. SurveyExactRank is used to keep count of unsuccessful attempts on a survey

#              @survey.OverQuotaCount = @survey.OverQuotaCount + 1

#              @survey.SurveyExactRank = @survey.SurveyExactRank + 1
#              print '********************************* Unsuccessful attempts count raised by 1 following an OQ for survey number: ', params[:tsfn]
#              puts
            
#              @survey.save
            
          

              # Give user chance to take another survey
          
              if (@user.SupplierLink.empty? == false) then
        
#              if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                print 'User will be sent to this survey: ', @user.SupplierLink[0]
                puts
                @NextEntryLink = @user.SupplierLink[0]
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink
           
#              else
        
        #      print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
#                print 'User will be sent to this survey: ', @user.SupplierLink[0]
#                puts
          #    @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
#                @NextEntryLink = @user.SupplierLink[0]
            #  @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
#                @user.SupplierLink = @user.SupplierLink.drop(1)
#                @user.save
#                redirect_to @NextEntryLink
#              end
            
              else # if SupplierLink empty
            
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=6'
            
              end # if SupplierLink empty
            
            
            
            
            
            
            else
              
              # save attempt info in User and Survey tables
              @user = User.find_by user_id: params[:PID]


              print 'OQuota for user_id: ', params[:PID], ' CID: ', @user.clickid
              puts          
          
              @user.SurveysAttempted << params[:tsfn]+'-4'
              @user.save
          
          
              @survey = Survey.find_by SurveyNumber: params[:tsfn]
            
              if (@survey == nil) then
                sleep(1)
                @survey = Survey.find_by SurveyNumber: params[:tsfn]
                puts " *********** Retried retrieving survey"
              else
              end    
          
              # Increment unsuccessful attempts. SurveyExactRank is used to keep count of unsuccessful attempts on a survey

              @survey.OverQuotaCount = @survey.OverQuotaCount + 1

              @survey.SurveyExactRank = @survey.SurveyExactRank + 1
              print '********************************* Unsuccessful attempts count raised by 1 following an OQ for survey number: ', params[:tsfn]
              puts
            
              @survey.save
            
          

              # Give user chance to take another survey
          
              if (@user.SupplierLink.empty? == false) then
            
            
#          if @user.children != nil then
#            @childrenvalue = '&Age_and_Gender_of_Child='+@user.children[0]
#            if @user.children.length > 1 then
#              (1..@user.children.length-1).each do |i|
#                @childrenvalue = @childrenvalue+'&Age_and_Gender_of_Child='+@user.children[i]
#              end
#            else
#            end
#          else
#          end
            
            
            
#            if @user.country=="9" then 
#              @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP='+@user.ZIP+'&HISPANIC='+@user.ethnicity+'&ETHNICITY='+@user.race+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_US='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#            else
#              if @user.country=="6" then
#                @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&ZIP_Canada='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#              else
#                if @user.country=="5" then
#                  @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_AU='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#                else
#                  if @user.country=="7" then
#                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&Fulcrum_ZIP_IN='+@user.ZIP+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#                  else
#                    puts "*************************************** Redirects: Find out why country code is not correctly set"
#                    @RepeatAdditionalValues = '&AGE='+@user.age+'&GENDER='+@user.gender+'&STANDARD_EDUCATION='+@user.eduation+'&STANDARD_HHI_INT='+@user.householdincome+'&STANDARD_EMPLOYMENT='+@user.employment+'&STANDARD_INDUSTRY_PERSONAL='+@user.pindustry+'&STANDARD_JOB_TITLE='+@user.jobtitle+@childrenvalue
#                    return
#                  end
#                end
#              end
#            end



#            @redirects_parsed_user_agent = UserAgent.parse(@user.user_agent)
    
#            print "*************************************** UseRide: User platform is: ", @redirects_parsed_user_agent.platform
#            puts
    
#            if @redirects_parsed_user_agent.platform == 'iPhone' then
      
#              @MS_is_mobile = '&MS_is_mobile=true'
#              p "*************************************** UseRide: MS_is_mobile is set TRUE"
      
#            else
#              @MS_is_mobile = '&MS_is_mobile=false'
#              p "*************************************** UseRide: MS_is_mobile is set FALSE"
      
#            end

        
              if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                print 'User will be sent to this survey: ', @user.SupplierLink[0]
                puts
                @NextEntryLink = @user.SupplierLink[0]
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink
           
              else
        
#              print 'User will be sent to this survey: ', @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
                print 'User will be sent to this survey: ', @user.SupplierLink[0]
                puts
#              @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues+@MS_is_mobile
                @NextEntryLink = @user.SupplierLink[0]
            #  @NextEntryLink = @user.SupplierLink[0]+params[:PID]+@RepeatAdditionalValues
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink
              end
            
              else # if SupplierLink empty
            
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=6'
            
              end # if SupplierLink empty
            
            end # RFG redirect          
          end # p2sredirect
        end # if test
              

      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
 
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
          
          if @rfg_redirect then
            # do nothing
            
          else # must be a FED redirect
            
            @survey = Survey.find_by SurveyNumber: params[:tsfn]
          
            if (@survey == nil) then
              sleep(1)
              @survey = Survey.find_by SurveyNumber: params[:tsfn]
              puts " *********** Retried retrieving survey"
            else
            end    
          
            # Increment unsuccessful attempts. SurveyExactRank is used to keep count of unsuccessful attempts on a survey

            @survey.SurveyExactRank = @survey.SurveyExactRank + 1
            print '***************************** Unsuccessful attempts count raised by 1 following a TERM for survey number: ', params[:tsfn]
            puts
            
            @survey.save
            
          end # if RFG redirect

          redirect_to 'https://www.ketsci.com/redirects/qterm?&QTERM=2'
          
        end # if test
        
    end # case
  end # status
end # class