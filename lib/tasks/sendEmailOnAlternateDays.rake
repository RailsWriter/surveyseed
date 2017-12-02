namespace :sendEmailOnAlternateDays do
	desc "ReminderMail"
	task :email_sender => :environment do
		print "Alternate Days Reminder Email started at #{Time.now}"
		puts
		
		User.where('surveyFrequency = ? AND emailId != ?', '2', "").each do |alternateDayUser|
			begin
				emailId=alternateDayUser.emailId
				print "Selected Alternate Days emailId: ", emailId
				puts
				PanelMailer.reminder_email(alternateDayUser).deliver_now
				print "Alternate Days Reminder Email sent to ", emailId, " at #{Time.now}"
				puts
				rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
				print "Problem sending Alternate Days Reminder mail to ", emailId, " due to message: ", e.message
				puts
			end
		end
	end
end