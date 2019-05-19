# This script reads a csv file listing potentially fraudulent Ketsci Ids. 
# It checks if those Ids are indeed Ketsci Ids. If so, then it finds the 
# clickids (external vendor Id) and Network Ids corresponding to those Ids.

require 'csv'

CSV.open('scripts/idsfile.csv', 'r')
CSV.open('scripts/blacklisted_idsfile.csv', 'w') do |i|
	CSV.foreach('scripts/idsfile.csv') do |row|
		ketsci_id = row[0].to_s

		user = User.where('user_id = ?', ketsci_id).first
		
		if user == nil then
			print ketsci_id, " NOT a Ketsci Id"
			puts
			i << [ketsci_id, "NOT a Ketsci Id"]
		else
			user.black_listed = true
			user.save

			blacklisted_id = user.clickid
			network = user.netid
			i << [ketsci_id, blacklisted_id, network]
			print "ketsci_id: ", ketsci_id, " blacklisted_clickid: ", blacklisted_id, " network: ", network
			puts
		end
	end
end