namespace :sendEmailOnAlternateDays do
	desc "ReminderMail"
	task :email_sender => :environment do
		puts "Alternate Days Reminder Email started at #{Time.now}\n"

		# user=User.last
		# emailId=user.emailId
		# PanelMailer.reminder_email(emailId).deliver_now
		
		User.where('surveyFrequency = ?', '2').each do |alternateDayUser|
			emailId=alternateDayUser.emailId
			PanelMailer.reminder_email(emailId).deliver_now
			puts "Alternate Days Reminder Email sent to ", emailId, " at #{Time.now}\n"
		end
	end
end