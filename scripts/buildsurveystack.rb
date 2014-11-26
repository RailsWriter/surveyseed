# This script runs every few hrs (15 mins min) to get suitable surveys from Federated Sample Offerwall to Ketsci stack

require 'httparty'

# Get offerwall surveys from Federated Sample

begin
  sleep(5)
  puts 'CONNECTING FOR OFFERWALL SURVEYS LIST'
  offerwallresponse = HTTParty.get("http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/Surveys/AllOfferwall/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E")
    rescue HTTParty::Error => e
    puts 'HttParty::Error '+ e.message
    retry
end while offerwallresponse.code != 200

puts offerwallresponse
totalavailablesurveys = offerwallresponse["ResultCount"] - 1
puts totalavailablesurveys+1

(0..totalavailablesurveys).each do |i|
  if ((offerwallresponse["Surveys"][i]["CountryLanguageID"] == 6) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 7) || (offerwallresponse["Surveys"][i]["CountryLanguageID"] == 9)) && ((offerwallresponse["Surveys"][i]["StudyTypeID"] == 1) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 8) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 9) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 10) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 11) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 12) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 13) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 14) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 15) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 16) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 21) || (offerwallresponse["Surveys"][i]["StudyTypeID"] == 23)) && (offerwallresponse["Surveys"][i]["BidIncidence"] > 10) && (offerwallresponse["Surveys"][i]["BidLengthOfInterview"] < 31) then
    #	Survey = Survey.new
    #	Survey.SurveyName = offerwallresponse["Surveys"][i]["SurveyName"]
    #	Survey.SurveyNumber = offerwallresponse["Surveys"][i]["SurveyNumber"]
   
	  SurveyName = offerwallresponse["Surveys"][i]["SurveyName"]
	  SurveyNumber = offerwallresponse["Surveys"][i]["SurveyNumber"]
    puts 'PROCESSING i =', i
	  puts SurveyName, SurveyNumber, offerwallresponse["Surveys"][i]["CountryLanguageID"]
    
    # Get Survey Qualifications Information by SurveyNumber
    
    begin
      sleep(10)
      puts 'CONNECTING FOR QUALIFICATIONS INFORMATION'
      SurveyQualifications = HTTParty.get('http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/SurveyQualifications/BySurveyNumberForOfferwall/'+SurveyNumber.to_s+'?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
        rescue HTTParty::Error => e
        puts 'HttParty::Error '+ e.message
        retry
    end while SurveyQualifications.code != 200

    if SurveyQualifications["SurveyQualification"]["Questions"]!=nil then
      NumberOfQualificationsQuestions = SurveyQualifications["SurveyQualification"]["Questions"].length-1
      puts NumberOfQualificationsQuestions+1
    
      (0..NumberOfQualificationsQuestions).each do |j|
        # Survey.Questions = SurveyQualifications["SurveyQualification"]["Questions"]
        puts SurveyQualifications["SurveyQualification"]["Questions"][j]["QuestionID"]
      end
    else
      puts 'SurveyQualifications or Questions is NIL'
    end
    
    # Get Survey Quotas Information by SurveyNumber
    begin
      sleep(10)
      puts 'CONNECTING FOR QUOTA INFORMATION'
      SurveyQuotas = HTTParty.get('http://vpc-stg-apiloadbalancer-1968605456.us-east-1.elb.amazonaws.com/Supply/v1/SurveyQuotas/BySurveyNumber/'+SurveyNumber.to_s+'/5411?key=5F7599DD-AB3B-4EFC-9193-A202B9ACEF0E')
        rescue HTTParty::Error => e
        puts 'HttParty::Error '+ e.message
        retry
    end while SurveyQuotas.code != 200

    if SurveyQuotas["SurveyStillLive"] then
      NumberOfQuotas = SurveyQuotas["SurveyQuotas"].length-1
      puts NumberOfQuotas+1

      (0..NumberOfQuotas).each do |k|
        if SurveyQuotas["SurveyQuotas"][k]["NumberOfRespondents"]>0 then
          NumberOfRespondents = SurveyQuotas["SurveyQuotas"][k]["NumberOfRespondents"]
          SurveyQuotaCPI = SurveyQuotas["SurveyQuotas"][k]["QuotaCPI"]
          puts NumberOfRespondents, SurveyQuotaCPI
          puts SurveyQuotas["SurveyQuotas"][k]["Questions"]
        else
        end
      end
    else
    end
    
    # Assign an initial gross rank to the chosen survey
    
    case offerwallresponse["Surveys"][i]["Conversion"]
      when 0..49
        puts "Rank 1"
      when 50..100
        puts "Rank 2"
    end
    
    #	Survey.save
  else
  end
end