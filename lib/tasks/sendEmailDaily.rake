namespace :sendEmailDaily do
	desc "ReminderMail"
	task :email_sender => :environment do
		print "******** Daily Reminder Email Task Starting at #{Time.now} ************"
		puts

		User.where('surveyFrequency = ? AND emailId != ?', '1', "").each do |dailyUser|
			begin
				emailId=dailyUser.emailId
				print "Selected Daily emailId: ", emailId
				puts
				if (emailId == 'akhtarjameel@gmail.com') || (emailId == '2@3.4') || (emailId == 'dasriharsha@gmail.com') then
					begin
						PanelMailer.reminder_email(dailyUser).deliver_now
						print "Daily Reminder Email sent to ", emailId, " at #{Time.now}"
						puts
						rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
					    print "Problem sending Daily Reminder mail to ", emailId, "due to message: ", e.message
					    puts
					end
				else
				end
			end
		end	
	end
end