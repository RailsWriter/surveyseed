namespace :sendEmailWeekly do
	desc "ReminderMail"
	task :email_sender => :environment do
		puts "Weekly Reminder Email started at #{Time.now}\n"

		# user=User.last
		# emailId=user.emailId
		# PanelMailer.reminder_email(emailId).deliver_now
		
		User.where('surveyFrequency = ?', '7').each do |weeklyUser|
			emailId=weeklyUser.emailId
			PanelMailer.reminder_email(weeklyUser).deliver_now
			puts "Weekly Reminder Email sent to ", emailId, " at #{Time.now}\n"

		end
		
	end
end