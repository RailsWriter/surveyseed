# This script updates UsGeo table to include rfgCountyChoice in 'estimated_population' field.

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

command = '{ "command" : "livealert/datapoint/1", "name" : "County (US)"}'

time=Time.now.to_i
hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.hex2bin, Digest::SHA1)
uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")

Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
	req = Net::HTTP::Post.new uri
	req.body = command
	req.content_type = 'application/json'
	response = http.request req
	puts response.body
  CountyList = response.body && response.body.length >= 2 ? JSON.parse(response.body) : nil
end

# print "Third choice: ", CountyList["response"]["answers"][3]["en-US"]
# puts
print "State = ", CountyList["response"]["answers"][1]["en-US"][0..1]
puts
print "County = ", CountyList["response"]["answers"][1]["en-US"][3..-1]
puts

UsGeo.all.each do |geo|
  geo.estimated_population = 0 # we use this field to store rfgChoice number
  if geo.county != nil then
    countyDbName = geo.county.gsub(/[^0-9A-Za-z]/, '')
  else
    countyDbName = "None"
    geo.estimated_population = 0
  end
  if geo.StateAbrv != nil then
    stateDbName = geo.StateAbrv
  else
    stateDbName = "None"
    geo.estimated_population = 0
  end  
  # print "Looking for choice number for ", stateDbName, "-", countyDbName
#   puts
  
  
  @notFound = true
  (1..CountyList["response"]["answers"].length-1).each do |n|
    
    if ((CountyList["response"]["answers"][n]["en-US"][0..1] == stateDbName) && ((countyDbName.downcase).include?(CountyList["response"]["answers"][n]["en-US"][3..-1].gsub(/[^0-9A-Za-z]/, '').downcase))) then
      geo.estimated_population = n
      @notFound = false
      # print "--------------------------->>>>>>>>>>>>>>>>>>>>>>> Inserting choice number ", n, " for ", stateDbName, "-", countyDbName
#       puts
    else
    end
  end
  if (@notFound == true) then
    print "--------------------------->>>>>>>>>>>>>>>>>>>>>>> No choice number found for ", stateDbName, "-", countyDbName
    puts
  else
  end
  geo.save
end