# This script updates survey ranks to the new rankings to manage best yield


# KEPC = 0 until no conversion else = no. of completes/no. of total attempts (failure+success) * cpi

# Top: 1 is the best and 100 is the worst rank for EXISTING surveys that have converted and have a 0.02 =< KEPC

# New: 101 is the best and 200 is the worst rank for a lowest conversion rate (0 or 1) for a NEW survey with GEPC 1 or 2. (initial KEPC = 0)
# Try More: 201 is the best and 300 is the worst rank for a lowest conversion rate (0 or 1) for an EXISTING survey with GEPC 1 or 2 or 0.01 =< KEPC < 0.02
# GEPC=5: 301 is the best and 400 is the worst rank for a lowest conversion rate (0 or 1) for an NEW or EXISTING survey with GEPC 5. (initial KEPC = 0)

# Bad: 401 is the best and 500 is the worst rank for EXISTING surveys that have converted and have a 0 < KEPC < 0.01
# Horrible: 501 is the best and 600 is the worst rank for EXISTING surveys that did not convert after MAX (20) attempts and have KEPC = 0


begin
# set timer to run every 20 mins

  starttime = Time.now
  print 'YieldManager: Time at start', starttime
  puts
    
  Survey.all.each do |toberankedsurvey|

      # Safety 1-95
      if (0 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 95) then
          
        # Only low CPI TCR > 0.05 (fast converters) in this group. Surveys arrive in TCR order. If they do not perform move them to Horrible.
    
        if (toberankedsurvey.TotalRemaining == 0) then
          
          if toberankedsurvey.Conversion == 0 then
            toberankedsurvey.SurveyGrossRank = 800
            toberankedsurvey.label = 'D: Rem = 0'
          
          else

            toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
            print "Assigned 0 Remaining to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            puts
            toberankedsurvey.label = 'D: Rem = 0'
          end
        
        else        
    
          
          @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
          
          if (@toberankedsurveyNumberofAttemptsSinceLastComplete > 20) then  # worst than 5% conversion rate i.e. 20 more after they were moved out of New
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              p "Found a toberankedsurvey with Conversion = 0"
              toberankedsurvey.Conversion = 700
              toberankedsurvey.label = 'H: CPI<1.5 and TCR<0.5'
              
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
            puts
            toberankedsurvey.label = 'S: Repositioned'
            
          end
        end # TotalRemaining
            
 
      else # not in 1-95 rank range
      end # not in 1-95 rank range
        
      # Showcase 96-100
      if (95 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 100) then
        # do nothing. surveys are put here manually to give them quick exposure to traffic
      else
      end  # not in 96-100 range
      
      # Fast Converters 101-200        
      if (100 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 200) then
          
        # Only high CPI and TCR > 0.05 (fast converters) in this group. Surveys arrive in TCR order. If they do not perform move them to OldTimers & Bad.          
          
        if (toberankedsurvey.TotalRemaining == 0) then
            
          if toberankedsurvey.Conversion == 0 then
            toberankedsurvey.SurveyGrossRank = 800
            toberankedsurvey.label = 'D: Rem = 0'
            
          else

            toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
            print "Assigned 0 Remaining to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            puts
            toberankedsurvey.label = 'D: Rem = 0'
          end
          
        else
          
          @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
          
          if (@toberankedsurveyNumberofAttemptsSinceLastComplete > 20) then
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              p "Found a toberankedsurvey with Conversion = 0"
              toberankedsurvey.Conversion = 600
              toberankedsurvey.label = 'OT: TCR<0.5'
              
            else
            
              toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
              print "Assigned Fast survey to Old Timer: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts
              toberankedsurvey.TCR = 1.0 / @toberankedsurveyNumberofAttemptsSinceLastComplete
              toberankedsurvey.label = 'OT: TCR<0.5'
            end
            
          else
            
            toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
            print "Reposition Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            toberankedsurvey.label = 'F: TCR>1 Repositioned'
            
          end
          
        end # TotalRemaining          
          
          
    
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
         
        if (toberankedsurvey.TotalRemaining == 0) then
            
          if toberankedsurvey.Conversion == 0 then
            toberankedsurvey.SurveyGrossRank = 800
            toberankedsurvey.label = 'D: Rem = 0'
            
          else

            toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
            print "Assigned 0 Remaining to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            puts
            toberankedsurvey.label = 'D: Rem = 0'
          end
          
        else         
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.10) then # (1 in 10 hits)
            
            if (toberankedsurvey.CPI > 1.49) then
            
              toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
              print "Assigned New survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>1'
            
            else
            
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
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
              
              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                toberankedsurvey.Conversion = 500
                print "Assigned a GCR>=0.01 to GCR<0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts   
                toberankedsurvey.label = 'GCR<0.1: GCR changed in GCR>=0.01'
                
              else
    
                toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
                print "Assigned a Try More to GCR<0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts   
                toberankedsurvey.label = 'GCR<0.1: GCR changed in GCR>=0.01'
              end        
              
            else # GCR>=0.01
      
                if (toberankedsurvey.SurveyExactRank > 10) then
                  
                  if (@GCR >= 1) then
                    toberankedsurvey.SurveyGrossRank = 301
                    print "Assigned GCR<0.01 to TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts 
                    toberankedsurvey.label = 'TM: Hits>10 & GCR >= 0.01'
                  else
    
                    toberankedsurvey.SurveyGrossRank = 400-(100*@GCR)
                    print "Assigned NEW/GCR>0.01 to Try More: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                    puts    
                    toberankedsurvey.label = 'TM: Hits>10 & GCR >= 0.01'
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
                    
        end  # TotalRemaining
    
      else # not in 201-300 rank range
      end # not in 201-300 rank range
    
      # Try More 301-400
      if (300 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 400) then    
          
        # These surveys are here to get another 10 attempts (10 to 20). If they convert move them to Fast else take them to Horrible        
          
        if (toberankedsurvey.TotalRemaining == 0) then
            
          if toberankedsurvey.Conversion == 0 then
              toberankedsurvey.SurveyGrossRank = 800
              toberankedsurvey.label = 'D: Rem = 0'
            
            else

              toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
              print "Assigned 0 Remaining to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts
              toberankedsurvey.label = 'D: Rem = 0'
            end
          
        else                            
            
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then
            
            if (toberankedsurvey.CPI > 1.49) then
            
              toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
              print "Assigned Try more survey to Top: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>0.5'
          
            else   
            
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
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
             
              if (@GCR >= 0.01) then
                
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
                
              else # GCR changed to <= 0.01
                
                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                  toberankedsurvey.Conversion = 500
                  print "Assigned a Try More to GCR<0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts   
                  toberankedsurvey.label = 'GCR<0.1: GCR changed in TM'
                  
                else
      
                  toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
                  print "Assigned a Try More to GCR<0.01: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts   
                  toberankedsurvey.label = 'GCR<0.1: GCR changed in TM'
                end
                
               end # @GCR values 
                
            else # No. of hits > 20
        
              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                p "Found a toberankedsurvey with Conversion = 0"
                toberankedsurvey.Conversion = 700
                toberankedsurvey.label = 'H: Hits>20, TCR=0'
                
              else
      
                toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
                print "Assigned a Try More to Horrible: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts   
                toberankedsurvey.label = 'H: Hits>20, TCR=0'
              end
          
            end # No. of hits
          
          else # number of completes = 0
          end # number of completes = 0
           
        end  # TotalRemaining 
                
      else # not in rank 401-500 range
      end # not in rank 301-400 range
    
      # New+GCR<0.01 401-500
      if (400 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 500) then
        
        # This is the place for new GCR<0.01 surveys. If they make TCR>0.5 then move to Fast or Safety. Move to OldTimers and Bad if TCR<0.5 but more than 0. They move to Horrible if they do not complete in 10. If they turn GCR>=0.01 then move them to GCR>=0.01. 
          
          
        if (toberankedsurvey.TotalRemaining == 0) then
            
          if toberankedsurvey.Conversion == 0 then
            toberankedsurvey.SurveyGrossRank = 800
            toberankedsurvey.label = 'D: Rem = 0'
            
          else

            toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
            print "Assigned 0 Remaining to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            puts
            toberankedsurvey.label = 'D: Rem = 0'
          end
          
        else              
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then # (1 in 10 hits)
          
            if (toberankedsurvey.CPI > 1.49) then
          
              toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
              print "Assigned GCR<0.01 survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>0.05 from GCR>=0.01'
          
            else   

                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
                print "Assigned GCR<0.01 survey to Safety: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'S: TCR>0.05 from GCR<0.01'
            
            end 
            
          else # Completes > 0 or TCR > 0.05
          end # Completes > 0 or TCR > 0.05
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.05)
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              toberankedsurvey.Conversion = 600
              toberankedsurvey.label = 'OT/B: 0<TCR<0.05'
            
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
                
                toberankedsurvey.SurveyGrossRank = 300-(100*@GCR)
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
                    toberankedsurvey.label = 'H: From GCR<0.01'
                  
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
                    toberankedsurvey.label = 'GCR<0.01: Repositioned'
              
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
         
         end  # TotalRemaining
 
          
      else # not in 301-400 rank range
      end # not in 301-400 rank range
      
      # Bad 501-600
      if (500 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 600) then
          
        # These are surveys that were good earlier but have fizzled to 0 < TCR < 0.05. The bad converters with TCR < 0.05 are also here. Ordered by Conversion. If their TCR becomes > 0.5 move them to Fast.
          
        if (toberankedsurvey.TotalRemaining == 0) then
            
            if toberankedsurvey.Conversion == 0 then
              toberankedsurvey.SurveyGrossRank = 800
              toberankedsurvey.label = 'D: Rem = 0'
            
            else

              toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
              print "Assigned 0 Remaining to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              puts
              toberankedsurvey.label = 'D: Rem = 0'
            end
          
        else
          
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then

            toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
            print "Assigned OldTimer survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            toberankedsurvey.label = 'F: TCR>0.05 in B'
          else
          end
            
            
          if (toberankedsurvey.CompletedBy.length == 0) then
            #Reposition according to latest Conversion
            
            if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
              toberankedsurvey.SurveyGrossRank = 600
              print "OT/B: Repositioned: ", toberankedsurvey.SurveyGrossRank
              puts
              toberankedsurvey.label = 'OT/B: Repositioned'
              
            else
            
              toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
              print "OT/B: Repositioned: ", toberankedsurvey.SurveyGrossRank
              puts
              toberankedsurvey.label = 'OT/B: Repositioned'
            end
            
          else
          end
          
        end  # TotalRemaining
    
      else # not in rank 501-600 range
      end # not in rank 501-600 range
  
      # Horrible 601-700
      if (600 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 700) then
    
         # These are surveys which have seen moree than 20 attempts without a complete, if GCR>=0.01 or 10 attempts if GCR<0.01. Ordered by Conversion. If they do start converting then move them to appropriate buckets. Low CPI surveys that fizzle also land up here.
          
        if (toberankedsurvey.TotalRemaining == 0) then
            
          if toberankedsurvey.Conversion == 0 then
            toberankedsurvey.SurveyGrossRank = 800
            toberankedsurvey.label = 'D: Rem = 0'
            
          else

            toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
            print "Assigned 0 Remaining to Dead: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
            puts
            toberankedsurvey.label = 'D: Rem = 0'
          end
          
        else          
   
          if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then
            
            if toberankedsurvey.CPI > 1.49 then

              toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100).to_i
              print "Assigned Horrible survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'F: TCR>0.05 from H'
              
            else
              
              toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100).to_i
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
            
            if toberankedsurvey.CPI > 0 then
              @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
            else
              @GCR = toberankedsurvey.GEPC
            end
                     
            @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
            
            if (@GCR>= 0.01) && (@toberankedsurveyNumberofAttemptsSinceLastComplete < 20) && (toberankedsurvey.CPI > 1.49) then
                
              if (@GCR >= 1) then
                toberankedsurvey.SurveyGrossRank = 301
                print "Assigned H to TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts 
                toberankedsurvey.label = 'TM: Hits>10 & GCR>=0.01'
              else

                toberankedsurvey.SurveyGrossRank = 400-(100*@GCR)
                print "Assigned H to Try More: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                puts    
                toberankedsurvey.label = 'TM: Hits>10 & GCR>=0.01'
              end         
            
            else     
            
              if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                toberankedsurvey.SurveyGrossRank = 700
                toberankedsurvey.label = 'H: Repositioned'
              
              else
            
                toberankedsurvey.SurveyGrossRank = 601+(100-toberankedsurvey.Conversion)
                print "Updated existing Horrible survey rank to: ", toberankedsurvey.SurveyGrossRank
                puts
                toberankedsurvey.label = 'H: Repositioned'
              end
            
            end # GCR, ALC, CPI conditions
            
          else
          end # no of completes = 0
           
        end  # TotalRemaining      
    
      else # not in rank 601-700 range
      end # not in rank 601-700 range
        
      # Dead 701-800
      if (700 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 800) then
          
        if (toberankedsurvey.TotalRemaining == 0) then
            
          # do nothing about it - stays dead
          
        else
            
            
            if (toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR >= 0.05) then
            
              if toberankedsurvey.CPI > 1.49 then

                toberankedsurvey.SurveyGrossRank = 201 - (toberankedsurvey.TCR * 100)
                print "Assigned Dead survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'F: TCR>0.05 from D'
              
              else
              
                toberankedsurvey.SurveyGrossRank = 101 - (toberankedsurvey.TCR * 100)
                print "Assigned Dead survey to Fast: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                toberankedsurvey.label = 'S: TCR>0.05 from D'
              end
              
            else
            end
            
            if ((toberankedsurvey.CompletedBy.length > 0) && (toberankedsurvey.TCR > 0) && (toberankedsurvey.TCR < 0.05)) then
            
              toberankedsurvey.SurveyGrossRank = 600 - (toberankedsurvey.TCR * 100)
              print "Assigned Dead survey to Bad: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
              toberankedsurvey.label = 'B: TCR>0.05 from D'
            else
            end
          
            if (toberankedsurvey.CompletedBy.length == 0) then
              #Reposition according to latest Conversion
            
              if toberankedsurvey.CPI > 0 then
                @GCR = toberankedsurvey.GEPC / toberankedsurvey.CPI
              else
                @GCR = toberankedsurvey.GEPC
              end
                     
              @toberankedsurveyNumberofAttemptsSinceLastComplete = toberankedsurvey.SurveyExactRank - toberankedsurvey.NumberofAttemptsAtLastComplete
            
              if (@GCR>= 0.01) && (@toberankedsurveyNumberofAttemptsSinceLastComplete < 20) && (toberankedsurvey.CPI > 1.49) then
                
                if (@GCR >= 1) then
                  toberankedsurvey.SurveyGrossRank = 301
                  print "Assigned D to TM: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts 
                  toberankedsurvey.label = 'TM: Hits>10 & GCR>=0.01'
                else

                  toberankedsurvey.SurveyGrossRank = 400-(100*@GCR)
                  print "Assigned D to Try More: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
                  puts    
                  toberankedsurvey.label = 'TM: Hits>10 & GCR>=0.01'
                end         
            
              else     
            
                if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
                  toberankedsurvey.SurveyGrossRank = 800
                  toberankedsurvey.label = 'D: Repositioned'
              
                else
            
                  toberankedsurvey.SurveyGrossRank = 701+(100-toberankedsurvey.Conversion)
                  print "Updated existing Horrible survey rank to: ", toberankedsurvey.SurveyGrossRank
                  puts
                  toberankedsurvey.label = 'D: Repositioned'
                end
            
              end # GCR, ALC, CPI conditions
            
            else
            end # no of completes = 0
            
        end
          
      else
      end # Dear range 701-800
        
       # Ignore 801-900
      if (800 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 900) then
        # do nothing. surveys are put here manually to hide them from ranking
      else
      end  # not in 801-900 range
  
  toberankedsurvey.save!

  end # for all toberankedsurvey 
  


      timenow = Time.now
  
      print 'YieldManager: Time at end', timenow
      puts
      if (timenow - starttime) > 1200 then 
        print 'time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
        puts
        timetorepeat = true
      else
        print 'time elapsed since start =', (timenow - starttime), '- going to sleep for 10 minutes'
        puts
        sleep (10.minutes)
        timetorepeat = true
      end

    end while timetorepeat

