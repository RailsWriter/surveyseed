namespace :sendEmailWeekly do
	desc "ReminderMail"
	task :email_sender => :environment do
		print "Weekly Reminder Email started at #{Time.now}"
		puts

		User.where('surveyFrequency = ? AND emailId != ?', '7', "").each do |weeklyUser|
			begin
				emailId=weeklyUser.emailId
				print "Selected Weekly emailId: ", emailId
				puts
				PanelMailer.reminder_email(weeklyUser).deliver_now
				print "Weekly Reminder Email sent to ", emailId, " at #{Time.now}"
				puts
				rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
				print "Problem sending Weekly Reminder mail to ", emailId, "due to message: ", e.message
				puts
			end
		end
		
	end
end