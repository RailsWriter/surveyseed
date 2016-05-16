class RedirectsController < ApplicationController
  def status
    
    require 'base64'
    require 'hmac-sha1'
    require 'mixpanel-ruby'
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
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
              
              @rfgUrl = request.original_url
              @ParseUrl = @rfgUrl.partition ("?")                
              @split2 = @ParseUrl[2]
              @ParseAgain = @split2.partition ("&hash")
              @plaintext = @ParseAgain[0]
                
              print "********************* Calculating HMAC for: ", @plaintext
              puts
      
              rfgSecretKey = 'BZ472UWaLhHO2AtyfeDgzPOTi0435puCjsgSR9D20wZUFBIt2OluFxg1aNW380zR'      
              @rfgHmac = HMAC::MD5.new(rfgSecretKey).update(@plaintext).hexdigest()
      
              if params[:hash] != @rfgHmac then
                @rfg_redirect = false
                print "**********************RFG HMAC did NOT match"
                puts
                print "params[:hash]= ", params[:hash], ' Calculated @rfgHmac= ', @rfgHmac
                puts
                
                # security term this interaction
                params[:status]="5"
                print "**********************Set params[:status] = 5 for QTERM"
                puts
                
              else
                @rfg_redirect = true
                print "**********************RFG HMAC matched!"
                puts
              end      
               
            else
              redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=0b'
              return
            end
          end
        end
      end
    else
      p '****************** Redirects: Signature verified **********************'
    end
        
    # SurveyExactRank is a counter for failures+OQ+Term on FED    
    
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

        end # if test


      when "2"
        # SuccessLink: https://www.ketsci.com/redirects/status?status=2&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]&cost=[%COST%]
        
        # save attempt info in User and Survey tables

        if params[:PID] == 'test' then
          redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=0'
          
        else  
          if @p2s_redirect then
            
            # save attempt info in User and Survey tables
          
            @user = User.find_by user_id: params[:PID]

            print '******************* Suceess in P2S router for user_id/PID: ', params[:PID], ' CID: ', @user.clickid
            puts
            
            if @user.SurveysCompleted.flatten(2).include? (@user.clickid) then
              print "************* Click Id already exists - do not postback again!"
              puts
      
            else
            
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
              
              if @user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then 
                @net_name = "Fyber2"
              else
              end
              
              if @user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then 
                @net_name = "SS3"
              else
              end
              
              if @user.netid == "Gd7a7dAkkL333frcsLA21aaH" then 
                @net_name = "MemoLink"
              else
              end 
              
              if @user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then 
                @net_name = "RadiumOne2"
              else
              end         
            
              if @user.netid == "T2Abd5433LLA785410lpH567" then 
                @net_name = "TestNtk"
              else
              end    
                            
              @user.SurveysCompleted[params[:PID]] = [Time.now, 'P2Ssurvey', 'P2S', '$1.25', @user.clickid, @net_name]
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
                  @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
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
              
              if @user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then

                begin
                  @Fyber2PostBack = HTTParty.post('http://www2.balao.de/SPNcu?transaction_id='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                  rescue HTTParty::Error => e
                    puts 'HttParty::Error '+ e.message
                    retry
                  end while @Fyber2PostBack.code != 200
    
              else
              end
              
              if @user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then
                # puts "************---------------->>>>>> WAITING FOR POSTBACK URL ********************------------------<<<<<<<<<<<<<<<<<<"

                begin
                  @SS3PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                        rescue HTTParty::Error => e
                          puts 'HttParty::Error '+ e.message
                          retry
                end while @SS3PostBack.code != 200
    
              else
              end
              
              if @user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then
     
                begin
                  @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                   rescue HTTParty::Error => e
                     puts 'HttParty::Error '+ e.message
                     retry
                end while @RadiumOnePostBack.code != 200
  
              else
              end
                                               
              # Keep a count of completes on each Network
            
              puts "*************** Keeping track of completes on the corresponding network"
            
              @net = Network.find_by netid: @user.netid
            
              if @net.Flag3 == nil then
              
                @net.Flag3 = "1" 
                @net.save
              
              else

                @net.Flag3 = (@net.Flag3.to_i + 1).to_s
                @net.save

              end
              
              
              # Count P2S completes
                            
              @P2Snet = Network.find_by netid: "2222"
              if @P2Snet.Flag3 == nil then
              
                @P2Snet.Flag3 = "1" 
                @P2Snet.save
              
              else
              
                @P2Snet.Flag3 = (@P2Snet.Flag3.to_i + 1).to_s
                @P2Snet.save
              
              end
                                        
            end # duplicate is false
             
            # Happy ending
            
            tracker.track(@user.ip_address, 'P2S_Completes')
            
            if @user.netid == "Gd7a7dAkkL333frcsLA21aaH" then
              redirect_to 'https://www.ketsci.com/redirects/successMML?&SUCCESS=1'
            else
              redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=1'    
            end            
        
          else # not a P2S project
            
            if @rfg_redirect then
             
              # save attempt info in User and Survey tables
          
              @user = User.find_by user_id: params[:PID]              

              print '************** Suceess for user_id/PID on RFG: ', params[:PID], ' CID: ', @user.clickid
              puts
          
              @user.SurveysAttempted << params[:tsfn]+'-2'
              
              @project = RfgProject.find_by rfg_id: params[:tsfn]
            
              if (@project == nil) then
                sleep(1)
                @project = RfgProject.find_by rfg_id: params[:tsfn]
                puts " *********** Retried retrieving project"
              else
              end    
                 
              print '************ Successfully completed project:', @project.rfg_id
              puts
              
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
              
              if @user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then 
                @net_name = "Fyber2"
              else
              end
              
              if @user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then 
                @net_name = "SS3"
              else
              end 
              
              if @user.netid == "Gd7a7dAkkL333frcsLA21aaH" then 
                @net_name = "MemoLink"
              else
              end           
              
              if @user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then 
                @net_name = "RadiumOne2"
              else
              end
              
              if @user.netid == "T2Abd5433LLA785410lpH567" then 
                @net_name = "TestNtk"
              else
              end
             
              @user.SurveysCompleted[params[:PID]] = [Time.now, params[:tsfn], 'RFG', @project.cpi, @user.clickid, @net_name]
              @user.save
              
             
              # Save completed project info in a hash with User_id number as key {params[:PID] => [params[:tis], params[:tsfn]], ..}            
              @project.CompletedBy[params[:PID]] = [Time.now, params[:tis], @user.clickid, @net_name]
  
              # Save attempts counts
              if (@project.NumberofAttempts == nil) then
                @project.NumberofAttempts = 0
              else
              end
              
              if (@project.AttemptsAtLastComplete == nil) then
                @project.AttemptsAtLastComplete = 0
              else
              end
                            
              @project.NumberofAttempts = @project.NumberofAttempts + 1
              #@RFGAttemptsSinceLastComplete = @project.NumberofAttempts - @project.AttemptsAtLastComplete
              @project.AttemptsAtLastComplete = @project.NumberofAttempts
              #if @RFGAttemptsSinceLastComplete  > 20 then
               # @project.epc = "$.00"
                #@project.projectEPC = "$.00"
                #else
                #end
              
              print "Updating Attempts count for project in Success: ", @project.rfg_id
              puts
              @project.save
  

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
                  @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
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
              
              if @user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then

                begin
                  @Fyber2PostBack = HTTParty.post('http://www2.balao.de/SPNcu?transaction_id='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                  rescue HTTParty::Error => e
                    puts 'HttParty::Error '+ e.message
                    retry
                  end while @Fyber2PostBack.code != 200
    
              else
              end   
                            
              if @user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then
                #puts "************---------------->>>>>> WAITING FOR POSTBACK URL ********************------------------<<<<<<<<<<<<<<<<<<"
                
                begin
                  @SS3PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                        rescue HTTParty::Error => e
                          puts 'HttParty::Error '+ e.message
                          retry
                end while @SS3PostBack.code != 200
    
              else
              end
              
              if @user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then
     
                begin
                  @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                   rescue HTTParty::Error => e
                     puts 'HttParty::Error '+ e.message
                     retry
                  end while @RadiumOnePostBack.code != 200
  
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


              # Count RFG completes
              
              @RFGnet = Network.find_by netid: "3333"
              if @RFGnet.Flag3 == nil then
              
                @RFGnet.Flag3 = "1" 
                @RFGnet.save
              
              else
              
                @RFGnet.Flag3 = (@RFGnet.Flag3.to_i + 1).to_s
                @RFGnet.save
              
              end
              
              # Happy ending
              
              tracker.track(@user.ip_address, 'RFG_Completes')
              
              if @user.netid == "Gd7a7dAkkL333frcsLA21aaH" then
                redirect_to 'https://www.ketsci.com/redirects/successMML?&SUCCESS=2'
              else
                redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=2'
              end        
                           
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
              
              if @user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then 
                @net_name = "Fyber2"
              else
              end 
              
              if @user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then 
                @net_name = "SS3"
              else
              end  
              
              if @user.netid == "Gd7a7dAkkL333frcsLA21aaH" then 
                @net_name = "MemoLink"
              else
              end   
              
              if @user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then 
                @net_name = "RadiumOne2"
              else
              end           
              
              if @user.netid == "T2Abd5433LLA785410lpH567" then 
                @net_name = "TestNtk"
              else
              end              
 
              @survey = Survey.find_by SurveyNumber: params[:tsfn]                    
              print '************ Successfully completed survey:', @survey.SurveyNumber
              puts
            
              @user.SurveysCompleted[params[:PID]] = [Time.now, params[:tsfn], 'FED', @survey.CPI, @user.clickid, @net_name]
              @user.save
              
              # Save completed survey info in a hash with User_id number as key {params[:PID] => [params[:tis], params[:tsfn]], ..}          
            
              @survey.CompletedBy[params[:PID]] = [Time.now, params[:tis], @user.clickid, @net_name]
              @survey.save!

              # Save (inverse of) TCR and reset counter for attempts at last complete
            
              @survey.SurveyExactRank = @survey.SurveyExactRank + 1  # SurveyExactRank=Failure+OQ+Success count
              @NumberofAttemptsSinceLastComplete = @survey.SurveyExactRank - @survey.NumberofAttemptsAtLastComplete
              @survey.TCR = (1.0 / @NumberofAttemptsSinceLastComplete).round(3)

              @survey.NumberofAttemptsAtLastComplete = @survey.SurveyExactRank
            
              # Move the just converted survey to F or S immediately, if it is already not there
            
              if (@survey.SurveyGrossRank > 100) then
      
                @survey.SurveyGrossRank = 101 - (@survey.TCR * 100)
                print "************** Assigned Just converted to Fast: ", @survey.SurveyGrossRank, ' Survey number = ', @survey.SurveyNumber
                @survey.label = 'JUST CONVERTED'

              else

                # the survey is already in F i.e. rank is <= 100. do nothing

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
                    @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
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
              
              if @user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then

                begin
                  @Fyber2PostBack = HTTParty.post('http://www2.balao.de/SPNcu?transaction_id='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                  rescue HTTParty::Error => e
                    puts 'HttParty::Error '+ e.message
                    retry
                  end while @Fyber2PostBack.code != 200
    
              else
              end
                          
              if @user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then
                # puts "************---------------->>>>>> WAITING FOR POSTBACK URL ********************------------------<<<<<<<<<<<<<<<<<<"
                
                begin
                  @SS3PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                        rescue HTTParty::Error => e
                          puts 'HttParty::Error '+ e.message
                          retry
                end while @SS3PostBack.code != 200
    
              else
              end
              
              if @user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then
                  
                  begin
                    @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+@user.clickid, :headers => { 'Content-Type' => 'application/json' })
                     rescue HTTParty::Error => e
                       puts 'HttParty::Error '+ e.message
                       retry
                  end while @RadiumOnePostBack.code != 200
  
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
              
              tracker.track(@user.ip_address, 'FED_Completes')
              
              if @user.netid == "Gd7a7dAkkL333frcsLA21aaH" then
                redirect_to 'https://www.ketsci.com/redirects/successMML?&SUCCESS=3'
              else
                redirect_to 'https://www.ketsci.com/redirects/success?&SUCCESS=3'
              end
              
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
            tracker.track(@user.ip_address, 'FL-3')
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=3'
            
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
              else
              end
              
              # Save attempts counts by project
              
              @project = RfgProject.find_by rfg_id: params[:tsfn]
              
              if (@project.NumberofAttempts == nil) then
                @project.NumberofAttempts = 0
              else
              end         
              
              @project.NumberofAttempts = @project.NumberofAttempts + 1
              #@RFGAttemptsSinceLastComplete = @project.NumberofAttempts - @project.AttemptsAtLastComplete
              #@project.AttemptsAtLastComplete = @project.NumberofAttempts
             # if @RFGAttemptsSinceLastComplete  > 20 then
              #  @project.epc = "$.00"
               # @project.projectEPC = "$.00"
              #else
              #end
              
              print "Updating Attempts count for project in Fail: ", @project.rfg_id
              puts  
              @project.save

            
              # Give user chance to take another survey unless they do not qualify for any (other) survey

              if (@user.SupplierLink.empty? == false) then
                          
                  print 'User will be sent to this survey: ', @user.SupplierLink[0]
                  puts
                  @NextEntryLink = @user.SupplierLink[0]
                  @user.SupplierLink = @user.SupplierLink.drop(1)
                  @user.save
                  redirect_to @NextEntryLink

              else # if SupplierLink empty?
                tracker.track(@user.ip_address, 'FL-4')
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=4'
              
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

                if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                  print 'User will be sent to this p2s survey: ', @user.SupplierLink[0]
                  puts
                  @NextEntryLink = @user.SupplierLink[0]
                  @user.SupplierLink = @user.SupplierLink.drop(1)
                  @user.save
                  redirect_to @NextEntryLink
           
                else

                  print 'User will be sent to this fed or rfg survey: ', @user.SupplierLink[0]
                  puts
                  @NextEntryLink = @user.SupplierLink[0]
                  @user.SupplierLink = @user.SupplierLink.drop(1)
                  @user.save
                  redirect_to @NextEntryLink

                end

              else # if SupplierLink empty?
                tracker.track(@user.ip_address, 'FL-5')
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=5'
              
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
            tracker.track(@user.ip_address, 'FL-6')
            redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=6'
          else # not a p2sredirect
            
            if @rfg_redirect then
            
              # save attempt info in User and Survey tables
              @user = User.find_by user_id: params[:PID]


              print 'OQuota for user_id: ', params[:PID], ' CID: ', @user.clickid
              puts          
          
              @user.SurveysAttempted << params[:tsfn]+'-4'
              @user.save    


              
              # Save attempts counts by project
              @project = RfgProject.find_by rfg_id: params[:tsfn]
              
              if (@project.NumberofAttempts == nil) then
                @project.NumberofAttempts = 0
              else
              end
              
              @project.NumberofAttempts = @project.NumberofAttempts + 1
              #@RFGAttemptsSinceLastComplete = @project.NumberofAttempts - @project.AttemptsAtLastComplete
              #@project.AttemptsAtLastComplete = @project.NumberofAttempts
              #if @RFGAttemptsSinceLastComplete  > 20 then
               # @project.epc = "$.00"
              #  @project.projectEPC = "$.00"
              # else
              # end
  
              print "Updating Attempts count for project in OQ: ", @project.rfg_id
              puts
              @project.save

          

              # Give user chance to take another survey
          
              if (@user.SupplierLink.empty? == false) then
        
#              if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                print 'User will be sent to this survey: ', @user.SupplierLink[0]
                puts
                @NextEntryLink = @user.SupplierLink[0]
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink
                       
              else # if SupplierLink empty
                tracker.track(@user.ip_address, 'FL-7')
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=7'
            
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
        
              if (@user.SupplierLink.length == 1) then #P2S is the next link
          
                print 'User will be sent to this survey: ', @user.SupplierLink[0]
                puts
                @NextEntryLink = @user.SupplierLink[0]
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink
           
              else
        
                print 'User will be sent to this survey: ', @user.SupplierLink[0]
                puts
                @NextEntryLink = @user.SupplierLink[0]
                @user.SupplierLink = @user.SupplierLink.drop(1)
                @user.save
                redirect_to @NextEntryLink
              end
            
              else # if SupplierLink empty
                tracker.track(@user.ip_address, 'FL-8')
                redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=8'
            
              end # if SupplierLink empty
            
            end # RFG redirect          
          end # p2sredirect
        end # if test
              

      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
 
        if (params[:PID] == 'test') || (@rfg_redirect == false) then
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
            
            # Save attempts counts by project
            @project = RfgProject.find_by rfg_id: params[:tsfn]
            
            if (@project.NumberofAttempts == nil) then
              @project.NumberofAttempts = 0
            else
            end
            
            @project.NumberofAttempts = @project.NumberofAttempts + 1
           # @RFGAttemptsSinceLastComplete = @project.NumberofAttempts - @project.AttemptsAtLastComplete
            #@project.AttemptsAtLastComplete = @project.NumberofAttempts
          #  if @RFGAttemptsSinceLastComplete  > 20 then
           #   @project.epc = "$.00"
            #  @project.projectEPC = "$.00"
            #else
            #end

            print "Updating Attempts count for project in TERM: ", @project.rfg_id
            puts
            @project.save
            
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
          tracker.track(@user.ip_address, 'QT-2')
          redirect_to 'https://www.ketsci.com/redirects/qterm?&QTERM=2'
          
        end # if test
        
    end # case
  end # status
end # class