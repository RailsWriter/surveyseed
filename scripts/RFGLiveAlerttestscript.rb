require 'digest/hmac'
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
command = '{ "command" : "livealert/listDatapoints/1"}'

#command = '{ "command" : "livealert/datapoint/1", "name" : "RFG2 STANDARD_EDUCATION_v2"}'
#command = '{ "command" : "livealert/datapoint/1", "name" : "RFG2 STANDARD_HHI_INT_v2"}'
#command = '{ "command" : "livealert/datapoint/1", "name" : "RFG2_Employment"}'
#command = '{ "command" : "livealert/datapoint/1", "name" : "RFG2_Ethnicity"}'
#command = '{ "command" : "livealert/datapoint/1", "name" : "STANDARD_JOB_TITLE"}'
#command = '{ "command" : "livealert/datapoint/1", "name" : "Employment Industry"}'
#command = '{ "command" : "livealert/datapoint/1", "name" : "isMobileDevice"}'

#command='{ "command" : "livealert/createLink/1", "rfg_id" : "RFG117241-010"}'
#command='{ "command" : "livealert/stats/1", "rfg_id" : "RFG117241-010"}'
#command='{ "command" : "livealert/log/1", "rfg_id" : "RFG117241-010"}'
#command = '{ "command" : "livealert/duplicateCheck/1", "rfg_id" : "RFG108677-024", "fingerprint" : 3825389918, "ip" : "166.78.136.138"}'
#command = '{ "command" : "offerwall/query/1", "rid" : "KETSCI_TEST", "country" : "US", "postalCode" : "94306", "gender" : "1", "birthday" : "1977-01-01"}'


time=Time.now.to_i
hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.hex2bin, Digest::SHA1)
uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")


Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
	req = Net::HTTP::Post.new uri
	req.body = command
	req.content_type = 'application/json'
	response = http.request req
	puts response.body
  ApiResponse = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil
end

print "Api Response: ", ApiResponse["response"]
puts
# print "Number of couties: ", CountyList["response"]["answers"].length
# puts
# # print "Choice: ", CountyList["response"]["answers"][2055]["en-US"]
# # puts
# print "State = ", CountyList["response"]["answers"][2013]["en-US"][0..1]
# puts
# print "County = ", CountyList["response"]["answers"][2013]["en-US"][3..-1]
# puts

#secret = [secret].pack("H*")

# Build secret hash to append as a param to URL

#unix_timestamp_in_s = Time.now.to_i
#secret_hash = Digest::HMAC.hexdigest("#{unix_timestamp_in_s}#{hash.to_json}", secret, Digest::SHA1)

#uri_string = "https://www.saysoforgod.com/API?apid=#{apid}&time=#{unix_timestamp_in_s}&hash=#{secret_hash}"

