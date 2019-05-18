require 'csv'

CSV.open('scripts/idsfile.csv', 'r')
CSV.open('scripts/aanicca_idsfile.csv', 'w') do |i|
	CSV.foreach('scripts/idsfile.csv') do |row|
		ketsci_id = row[0].to_s
		print ketsci_id
		puts

		user = User.where('user_id = ?', ketsci_id).first
		if user == nil then
			puts "NOT FOUND"
			i << [ketsci_id, "NOT FOUND"]
		else
			aanicca_id = user.clickid
			i << [ketsci_id, aanicca_id]
			print "aanicca_id =", aanicca_id
			puts
		end
	end
end