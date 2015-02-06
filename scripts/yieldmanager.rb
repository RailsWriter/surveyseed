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

  # Tops
  if (0 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 100) then

    toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))

    if 0.02 <= toberankedsurvey.KEPC then   

      # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
      if toberankedsurvey.KEPC * 100 >= 100 then
        toberankedsurvey.SurveyGrossRank = 1
        print "Assigned Top toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      else
        toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
        print "Assigned Top toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end

    else
    end

    if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    

      if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
        p "Found a toberankedsurvey with Conversion = 0"
        toberankedsurvey.Conversion = 1
      else
      end

      toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
      print "YM Updated existing 1-100 ranked toberankedsurvey to: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
      puts
    end

    if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then  

      if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
        p "Found a toberankedsurvey with Conversion = 0"
        toberankedsurvey.Conversion = 1
      else
      end

      toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
      print "YM Updated existing 1-100 ranked toberankedsurvey to: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
      puts
    end

  else # not in rank range
  end # not in rank range

  # New
  if (100 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 200) then

    if toberankedsurvey.CompletedBy.length > 0 then

      toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))

      # Unless KEPC > 1 it will be ordered by KEPC value in Top tier. It will always be above 98
      if toberankedsurvey.KEPC * 100 >= 100 then
        toberankedsurvey.SurveyGrossRank = 1
        print "Assigned NEW toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      else
        toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
        print "Assigned NEW toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end   

    else # for 0 number of completes

      if toberankedsurvey.SurveyQuotaCalcTypeID == 5 then
  
        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
        print "Assigned NEW toberankedsurvey a GEPC=5 tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
  
      else # GEPC = 1 or 2

        if toberankedsurvey.SurveyExactRank <= 10 then # No. of hits
  
          # do nothing - let it get few more hits
  
        else # No. of hits > 10
  
          # does not look like a fast converter - move it to 'Try More' group
  
          if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
            p "Found a toberankedsurvey with Conversion = 0"
            toberankedsurvey.Conversion = 1
          else
          end

          toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
          print "Assigned NEW toberankedsurvey rank to Try More tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts   
    
        end # No. of hits
  
      end # GEPC = 5

    end # end for number of completes

  else # not in rank range
  end # not in rank range
  
  

  # Try More  
  if (200 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 300) then

#    if toberankedsurvey.CompletedBy.length > 0 then
      if toberankedsurvey.CountryLanguageID > 0 then

      toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CountryLanguageID.to_f/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CountryLanguageID))     
      print "****************************** KEPC = ", toberankedsurvey.KEPC, 'for SurveyNumber', toberankedsurvey.SurveyNumber
      puts
      print "CPI: ", toberankedsurvey.CPI
      puts
      print "Division: ", (toberankedsurvey.CountryLanguageID/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CountryLanguageID))
      puts
      print "Numerator: ". toberankedsurvey.CountryLanguageID
      puts
      print "Denominator: ", (toberankedsurvey.SurveyExactRank + toberankedsurvey.CountryLanguageID)
      puts
      
      
      if 0.02 <= toberankedsurvey.KEPC then   
  
        # Unless KEPC > 1 it will be ordered by KEPC value in Top tier. It will always be above 98
        if toberankedsurvey.KEPC * 100 >= 100 then
          toberankedsurvey.SurveyGrossRank = 1
          print "Assigned Try More toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        else
          toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
          print "Assigned Try More toberankedsurvey rank to Top tier: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        end   
  
      else
      end
    
      if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
        print "Assigned existing Try More toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end

      if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then    

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
        print "Assigned existing Try More toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end 

    else # for number of completes

      if toberankedsurvey.SurveyQuotaCalcTypeID == 5 then
  
        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
        print "Assigned existing Try More toberankedsurvey a GEPC=5 tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
  
      else # GEPC = 5

        if toberankedsurvey.SurveyExactRank <= 20 then # No. of hits
  
          # do nothing - let it get few more hits
  
        else # No. of hits > 20
  
          # is a bad converter - move it to 'Try More' group
  
          if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
            p "Found a toberankedsurvey with Conversion = 0"
            toberankedsurvey.Conversion = 1
          else
          end

          toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
          print "Assigned a Try More toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts   
    
        end # No. of hits
  
      end # GEPC = 5

    end # end for number of completes

  else # not in rank range
  end # not in rank range

  # GEPC=5
  if (300 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 400) then

    if toberankedsurvey.CompletedBy.length > 0 then

      toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))     

      if 0.02 <= toberankedsurvey.KEPC then   
  
        # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
        if toberankedsurvey.KEPC * 100 >= 100 then
          toberankedsurvey.SurveyGrossRank = 1
          print "Assigned GEPC=5 toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        else
          toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
          print "Assigned GEPC=5 toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        end
  
      else
      end

      if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
        print "Assigned existing GEPC=5 toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end
 
      if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then   

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
        print "Assigned existing GEPC=5 toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end 

    else # for number of completes

      if toberankedsurvey.SurveyQuotaCalcTypeID == 5 then
  
        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 301+(100-toberankedsurvey.Conversion)
        print "Assigned existing GEPC=5 toberankedsurvey a GEPC=5 tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
  
      else # GEPC = 1 or 2 

        if toberankedsurvey.SurveyExactRank == 0 then # No. of hits
  
          if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
            p "Found a toberankedsurvey with Conversion = 0"
            toberankedsurvey.Conversion = 1
          else
          end

          toberankedsurvey.SurveyGrossRank = 101+(100-toberankedsurvey.Conversion)
          print "Assigned existing GEPC=5 toberankedsurvey a New Survey tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
  
        else # No. of hits = 0
        end
    
        if (0 < toberankedsurvey.SurveyExactRank) &&  (toberankedsurvey.SurveyExactRank <= 10) then # No. of hits 1-10
  
          if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
            p "Found a toberankedsurvey with Conversion = 0"
            toberankedsurvey.Conversion = 1
          else
          end

          toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
          print "Assigned existing GEPC=5 toberankedsurvey a Try More Survey tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
      
        else # No. of hits is 1-10
        end
  
  
        if (10 < toberankedsurvey.SurveyExactRank) &&  (toberankedsurvey.SurveyExactRank <= 20) then # No. of hits 11-20
  
          # is a bad converter - move it to 'Try More' group
  
          if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
            p "Found a toberankedsurvey with Conversion = 0"
            toberankedsurvey.Conversion = 1
          else
          end

          toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
          print "Assigned a GEPC=5 toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts   
    
        else # No. of hits is 11-20
        end
    
  
        if (20 < toberankedsurvey.SurveyExactRank) then # No. of hits 11-20
  
          # is a horrible converter - move it to Horrible group
  
          if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
            p "Found a toberankedsurvey with Conversion = 0"
            toberankedsurvey.Conversion = 1
          else
          end

          toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
          print "Assigned a GEPC=5 toberankedsurvey a Horrible tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts   
    
        else # No. of hits is 20+
        end
  
  
      end # GEPC = 5

    end # end for number of completes

  else # not in rank range
  end # not in rank range

  # The Bad
  if (400 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 500) then

    if toberankedsurvey.CompletedBy.length > 0 then

      toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))     

      if 0.02 <= toberankedsurvey.KEPC then   
  
        # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
        if toberankedsurvey.KEPC * 100 >= 100 then
          toberankedsurvey.SurveyGrossRank = 1
          print "Assigned Bad toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        else
          toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
          print "Assigned Bad toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        end
  
      else
      end

      if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
        print "Assigned existing Bad toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end

      if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then    

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
        print "Assigned existing Bad toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end 

    else # for number of completes      
    end # end for number of completes

  else # not in rank range
  end # not in rank range

  # Horrible
  if (500 < toberankedsurvey.SurveyGrossRank) && (toberankedsurvey.SurveyGrossRank <= 600) then

    if toberankedsurvey.CompletedBy.length > 0 then

      toberankedsurvey.KEPC = toberankedsurvey.CPI * (toberankedsurvey.CompletedBy.length/(toberankedsurvey.SurveyExactRank + toberankedsurvey.CompletedBy.length))     

      if 0.02 <= toberankedsurvey.KEPC then   
  
        # Unless KEPC > 1 the others are ordered by KEPC value. It will always be above 98
        if toberankedsurvey.KEPC * 100 >= 100 then
          toberankedsurvey.SurveyGrossRank = 1
          print "Assigned Horrible toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        else
          toberankedsurvey.SurveyGrossRank = 100 - (toberankedsurvey.KEPC * 100)
          print "Assigned Horrible toberankedsurvey to Top tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
          puts
        end
  
      else
      end

      if (0.01 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.02) then    

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 201+(100-toberankedsurvey.Conversion)
        print "Assigned existing Horrible toberankedsurvey a Try More tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end

      if (0 <= toberankedsurvey.KEPC) &&  (toberankedsurvey.KEPC < 0.01) then    

        if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
          p "Found a toberankedsurvey with Conversion = 0"
          toberankedsurvey.Conversion = 1
        else
        end

        toberankedsurvey.SurveyGrossRank = 401+(100-toberankedsurvey.Conversion)
        print "Assigned existing Horrible toberankedsurvey a Bad Converter tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
        puts
      end 

    else # for number of completes    

      if toberankedsurvey.Conversion == 0 then # to squeeze 101 conversion values in 100 levels
        p "Found a toberankedsurvey with Conversion = 0"
        toberankedsurvey.Conversion = 1
      else
      end

      toberankedsurvey.SurveyGrossRank = 501+(100-toberankedsurvey.Conversion)
      print "Assigned existing Horrible toberankedsurvey a Horrible tier rank: ", toberankedsurvey.SurveyGrossRank, ' Survey number = ', toberankedsurvey.SurveyNumber
      puts      
  
    end # end for number of completes

  else # not in rank range
  end # not in rank range

  
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
#    sleep (1200 - (timenow - starttime))
        timetorepeat = true
      end

    end while timetorepeat

