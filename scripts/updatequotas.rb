require 'httparty'

# Check if any survey's totalquota changed since last time checked 'today'

begin

  starttime = Time.now
  p 'At start at', starttime
  
  begin
    sleep(3)
#  today = DateTime.yesterday.strftime('%Y-%m-%d')
    today = "2014-11-25"
  
  
    puts 'CONNECTING FOR ALLOCATED SURVEYS WITH QUOTA UPDATES BY DATE'
    SurveyQuotaUpdatesByDate = HTTParty.get('http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/Surveys/SupplierAllocations/ByDate/'+today+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
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
        UpdatedSurveyQuotas = HTTParty.get('http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/SurveyQuotas/BySurveyNumber/'+@surveynumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
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
      puts 'i = ', i         
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