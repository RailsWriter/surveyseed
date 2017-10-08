require 'httparty'

api_base_url = "https://www.your-surveys.com/suppliers_api/surveys/user"
@failcount = 0
net_payout = 1.25

puts '*************** CONNECTING TO OFFERWALL for P2S SURVEYS'

begin
  @failcount = @failcount+1
  print "P2S API access failcount is: ", @failcount
  puts
	p2sApiResponse = HTTParty.get(api_base_url+'?user_id=KET_1&age=32&email=akht@bil.com&gender=m&zip_code=91123&ip_address=76.218.107.128',
		:headers => {'X-YourSurveys-Api-Key' => '5b96ba34dc040bf1baf557be93f8459f'}
		)
  rescue HTTParty::Error => e
    puts 'HttParty::Error '+ e.message
  retry
end while ((p2sApiResponse.code != 200) && (@failcount < 10))

P2SApiSupplierLinks = []
if @failcount ==10 then
  print "****DEBUG***** No response returned by P2S API. No SupplierLinks added. **********"
  puts
else
  print 'http response', p2sApiResponse
  puts
  if p2sApiResponse["surveys"].length == 0 then
      print "********* No surveys returned by P2S API **********"
      puts
  else
    NumberOfSurveys = p2sApiResponse["surveys"].length
    print "************ Number of surveys returned by P2S API: ", NumberOfSurveys
    puts

    (0..NumberOfSurveys-1).each do |i|
      if (p2sApiResponse["surveys"][i]["cpi"].to_f > net_payout) then
        P2SApiSupplierLinks << p2sApiResponse["surveys"][i]["entry_link"]
      else
      end
    end #do

    print "************ Number of surveys on P2S API which Qualify for KETSCI: ", P2SApiSupplierLinks.length
    puts
    print "P2S API Offerwall SupplierLinks: ", P2SApiSupplierLinks
    puts

    print "************>>>>User will be sent to this first P2S API Survey Entry link>>>>>>>ooooppppppp ", P2SApiSupplierLinks[0],  "***************************************************************"
    puts      
  end
end