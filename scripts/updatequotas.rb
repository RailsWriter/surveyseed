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



# Check if any survey's totalquota changed since last time checked 'today'

begin

  starttime = Time.now
  print 'At start at', starttime
  puts
  
  begin
    sleep(3)
    yesterday = DateTime.yesterday.strftime('%Y-%m-%d')
#    yesterday = "2014-11-30". Use yesterday to take care of midnight. It does not make it slow because actual updates are every 15 mins.
 
    print "Updating since DATE YYYY-MM-DD =", yesterday
    puts 'CONNECTING FOR ALLOCATED SURVEYS WITH QUOTA UPDATES BY DATE'
    
    if flag == 'prod' then
      SurveyQuotaUpdatesByDate = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/ByDate/'+yesterday+'?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
    else
      if flag == 'stag' then
        SurveyQuotaUpdatesByDate = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/ByDate/'+yesterday+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
      else
      end
    end
       
#    SurveyQuotaUpdatesByDate = HTTParty.get(base_url+'/Supply/v1/Surveys/SupplierAllocations/ByDate/'+yesterday+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
      rescue HTTParty::Error => e
        puts 'HttParty::Error '+ e.message
      retry
    end while SurveyQuotaUpdatesByDate.code != 200
  
    print 'SurveyQuotaUpdatesByDate', SurveyQuotaUpdatesByDate
    puts
    totalupdatedsurveys = SurveyQuotaUpdatesByDate["ResultCount"] - 1
    print 'totalupdatedsurveys', totalupdatedsurveys+1
    puts
  
    (0..totalupdatedsurveys).each do |i|
      @surveynumber = SurveyQuotaUpdatesByDate["SupplierAllocationSurveys"][i]["SurveyNumber"]
         
      # Get new quota info by surveynumber and overwrite in Survey table
  
      begin
        sleep(3)
        print 'CONNECTING FOR NEW QUOTA INFO for surveynumber =', @surveynumber
        puts
        
        if flag == 'prod' then
          UpdatedSurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5458?key=AA3B4A77-15D4-44F7-8925-6280AD90E702')
        else
          if flag == 'stag' then
            UpdatedSurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
          else
          end
        end
        
#        UpdatedSurveyQuotas = HTTParty.get(base_url+'/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
        
        rescue HTTParty::Error => e
          puts 'HttParty::Error '+ e.message
        retry
      end while UpdatedSurveyQuotas.code != 200

      # Save quotas information for each survey
  
      Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey|
        if (UpdatedSurveyQuotas["SurveyStillLive"]) then
          survey.SurveyStillLive = UpdatedSurveyQuotas["SurveyStillLive"]
          survey.SurveyStatusCode = UpdatedSurveyQuotas["SurveyStatusCode"]
          survey.SurveyQuotas = UpdatedSurveyQuotas["SurveyQuotas"]
          print 'Updating Surveynumber: ', @surveynumber
          puts
          survey.save
        else
          puts '**************************** Deleting a closed survey'
          survey.delete
        end
      end
      print 'Updated survey count i = ', i   
      puts      
    end

    timenow = Time.now
    print 'Time at end', timenow
    puts
    if (timenow - starttime) > 720 then 
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
      puts
      timetorepeat = true
    else
      print 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to sleep for 12 minutes'
      puts
      sleep (12.minutes)
 #     sleep (1800 - (timenow - starttime)).round
      timetorepeat = true
    end

end while timetorepeat