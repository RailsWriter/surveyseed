#require 'digest/hmac'
require 'openssl'
require 'net/http'
require 'uri'


class String
	def hex2bin
		scan(/../).map {|x| x.to_i(16).chr}.join
	end
end

apid = "54ef65c3e4b04d0ae6f9f4a7"
secret = "8ef1fe91d92e0602648d157f981bb934"

#command='{ "command" : "test/copy/1", "data1" : "KETSCI TEST"}'
#command='{ "command" : "livealert/inventory/1", "country" : "AU"}'
#command='{ "command" : "livealert/targeting/1", "rfg_id" : "RFG189829-008"}'
#command = '{ "command" : "livealert/listDatapoints/1"}'
#command = '{ "command" : "livealert/datapoint/1", "name" : "Computer Check"}'
#command='{ "command" : "livealert/createLink/1", "rfg_id" : "RFG117241-010"}'
#command='{ "command" : "livealert/stats/1", "rfg_id" : "RFG117241-010"}'
#command='{ "command" : "livealert/log/1", "rfg_id" : "RFG117241-010"}'
#command = '{ "command" : "livealert/duplicateCheck/1", "rfg_id" : "RFG108677-024", "fingerprint" : 3825389918, "ip" : "166.78.136.138"}'
command = '{ "command" : "offerwall/query/1", "rid" : "KETSCI_TEST", "country" : "US", "postalCode" : "94303", "gender" : "1", "birthday" : "1977-01-01"}'


time=Time.now.to_i
#hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.hex2bin, Digest::SHA1)
digest = OpenSSL::Digest.new('sha1')
hash = OpenSSL::HMAC.hexdigest(digest, secret.hex2bin, "#{time}#{command}")


uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")


Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
	req = Net::HTTP::Post.new uri
	req.body = command
	req.content_type = 'application/json'
	response = http.request req
	puts response.body
  OfferwallResponse = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil
end

print "Offerwall Response: ", OfferwallResponse["response"]
puts
# print "Number of couties: ", CountyList["response"]["answers"].length
# puts
# # print "Choice: ", CountyList["response"]["answers"][2055]["en-US"]
# # puts
# print "State = ", CountyList["response"]["answers"][2013]["en-US"][0..1]
# puts
# print "County = ", CountyList["response"]["answers"][2013]["en-US"][3..-1]
# puts

# Find RFG SupplierLink for max CR in the set of Offerwall surveys
@maxCRIndex = 0
@maxCR = OfferwallResponse["response"]["surveys"][@maxCRIndex]["projectCR"]
@RFGOfferwallSupplierLink = OfferwallResponse["response"]["surveys"][@maxCRIndex]["offer_url"]

print "************ @maxCR initialized to: ", @maxCR
puts

net_payout = "$1.25"

NumberOfSurveys = OfferwallResponse["response"]["surveys"].length
  
  print "************ Number of surveys: ", NumberOfSurveys
  puts

  (0..NumberOfSurveys-1).each do |i|
    if ((@maxCR < OfferwallResponse["response"]["surveys"][i]["projectCR"]) && (net_payout < OfferwallResponse["response"]["surveys"][i]["payout"])) then
      @maxCRIndex = i
  		@maxCR = OfferwallResponse["response"]["surveys"][i]["projectCR"]
  		@RFGOfferwallSupplierLink = OfferwallResponse["response"]["surveys"][i]["offer_url"]
  	else
  	end
  end

  print "RFG Offerwall SupplierLink: ", @RFGOfferwallSupplierLink, " at index: ", @maxCRIndex, " with projectCR: ", @maxCR, " and payout: ", OfferwallResponse["response"]["surveys"][@maxCRIndex]["payout"], " and IR: ", OfferwallResponse["response"]["surveys"][@maxCRIndex]["ir"]
  puts


  # end


