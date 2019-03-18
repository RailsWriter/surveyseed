require 'httparty'

net_payout = 1.25
user_id = "KETSCI_TESTER"
userCountry = "United States"

api_base_url = "http://innovate-stage-209385288.us-east-1.elb.amazonaws.com/api/v1"
@failcount = 0

begin
  @failcount = @failcount+1

  puts "*****************************************"
  puts "Start selecting InnovateMR API Surveys"
  puts "*****************************************"
  # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

  print "InnovateMR API access failcount is: ", @failcount
  puts

  @innovateMRAPINetId = "6666"
  IMRAPIpid = @innovateMRAPINetId + user_id

  
  # @innovateSupplierLink = ["http://innovate.go2cloud.org/aff_c?offer_id=821&aff_id=273&source=273&aff_sub="+@innovateNetId+user.user_id]

  puts "*****************************************"
  puts "End selecting InnovateMR API Surveys"
  puts "*****************************************"
  
  puts "*****************************************************"
  print "Full API call: ", api_base_url+'/supply/getAllocatedSurveys'
  puts
  puts "*****************************************************"


# Must include a good ip address not ::1, a valid zipcode

  innovateMRAPIResponse = HTTParty.get(api_base_url+'/supply/getAllocatedSurveys',
		:headers => {'x-access-token' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjVjNjMwMWRkN2M1ZWU5MWI4MDlmZThiYiIsInVzcl9pZCI6NDIyLCJ1c3JfdHlwZSI6InN1cHBsaWVyIiwiaWF0IjoxNTQ5OTkyNDE4fQ.bRm_V-FJ_fLvzVPOvlpRSDtBLaXnDhIduhSSmBfudHY',
      'Content-Type' => 'application/json'}
		)
  rescue HTTParty::Error => e
    puts 'HttParty::Error '+ e.message
  retry
end while ((innovateMRAPIResponse.code != 200) && (@failcount < 10))

innovateMRAPISupplierLink = []
if @failcount ==10 then
  print "****DEBUG***** No response returned by InnovateMR API. No SupplierLinks added. **********"
  puts
else
  # print 'http response: ', innovateMRAPIResponse
  # puts
  if innovateMRAPIResponse["result"].length == 0 then
      print "********* No surveys returned by InnovateMR API **********"
      puts
  else
    NumberOfSurveys = innovateMRAPIResponse["result"].length
    print "************ Number of surveys returned by InnovateMR API: ", NumberOfSurveys
    puts

    (0..NumberOfSurveys-1).each do |i| 
      if ((innovateMRAPIResponse["result"][i]["CPI"].to_f > net_payout) && (innovateMRAPIResponse["result"][i]["isQuota"]) && (innovateMRAPIResponse["result"][i]["Country"] == userCountry)) then        
        innovateMRAPISupplierLink << innovateMRAPIResponse["result"][i]["entryLink"].sub('[%%pid%%]',IMRAPIpid)
      else
      end
    end #do

    print "************ Number of surveys on InnovateMR API which Qualify for KETSCI: ", innovateMRAPISupplierLink.length
    puts
    print "InnovateMR API Offerwall SupplierLinks: ", innovateMRAPISupplierLink
    puts

    print "************>>>>User will be sent to this first InnovateMR API Survey Entry link>>>>>>>ooooppppppp ", innovateMRAPISupplierLink[0],  "***************************************************************"
    puts      
  end
end