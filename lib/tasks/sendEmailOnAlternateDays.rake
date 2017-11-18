namespace :sendEmailOnAlternateDays do
	desc "ReminderMail"
	task :email_sender => :environment do
		print "Alternate Days Reminder Email started at #{Time.now}"
		puts
		
		User.where('surveyFrequency = ? AND emailId != ?', '2', "").each do |alternateDayUser|
			emailId=alternateDayUser.emailId
			print "Selected AlternateDay emailId: ", emailId
			puts
			PanelMailer.reminder_email(alternateDayUser).deliver_now
			print "Alternate Days Reminder Email sent to ", emailId, " at #{Time.now}"
			puts
		end
	end
end