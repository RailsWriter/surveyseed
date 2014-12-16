require 'httparty'

# Set flag to 'prod' to use production and 'stag' for staging base URL

flag = 'prod'
prod_base_url = "http://vpc-apiloadbalancer-991355604.us-east-1.elb.amazonaws.com"
staging_base_url = "http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com"

p "**************************** QUOTA UPDATE: ENV is set to", flag

if flag == 'prod' then
  base_url = prod_base_url
else
  if flag == 'stag' then
    base_url = staging_base_url
  else
    p "******** QUOTA UPDATE: SET base URL correctly *******"
  end
end

p " ************* QUOTA UPDATE: base url is", base_url



# Check if any survey's totalquota changed since last time checked 'today'

begin

  starttime = Time.now
  p 'At start at', starttime
  
  begin
    sleep(3)
    yesterday = DateTime.yesterday.strftime('%Y-%m-%d')
#    yesterday = "2014-11-30"
 
    p "Updating since DATE YYYY-MM-DD =", yesterday
  
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
  
    puts SurveyQuotaUpdatesByDate
    totalupdatedsurveys = SurveyQuotaUpdatesByDate["ResultCount"] - 1
    puts totalupdatedsurveys+1
  
    (0..totalupdatedsurveys).each do |i|
      @surveynumber = SurveyQuotaUpdatesByDate["SupplierAllocationSurveys"][i]["SurveyNumber"]
         
      # Get new quota info by surveynumber and overwrite in Survey table
  
      begin
        sleep(3)
        puts 'CONNECTING FOR NEW QUOTA INFO for surveynumber =', @surveynumber
        
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
        survey.SurveyStillLive = UpdatedSurveyQuotas["SurveyStillLive"]
        survey.SurveyStatusCode = UpdatedSurveyQuotas["SurveyStatusCode"]
        survey.SurveyQuotas = UpdatedSurveyQuotas["SurveyQuotas"]
        puts 'Saving surveynumber: ', @surveynumber
        survey.save
      end
      puts 'Updated survey count i = ', i         
    end

    timenow = Time.now
    p 'Time at end', timenow
    if (timenow - starttime) > 1800 then 
      puts 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to repeat immediately'
      timetorepeat = true
    else
      puts 'QuotaUpdates: time elapsed since start =', (timenow - starttime), '- going to sleep for 30 minutes'
      sleep (30.minutes)
 #     sleep (1800 - (timenow - starttime)).round
      timetorepeat = true
    end

end while timetorepeat