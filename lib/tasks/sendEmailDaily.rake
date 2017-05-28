namespace :sendEmailDaily do
	desc "ReminderMail"
	task :email_sender => :environment do
		puts "******** Daily Reminder Email Task Starting ************\n"

		# user=User.last
		# emailId=user.emailId
		# PanelMailer.reminder_email(emailId).deliver_now
		
		User.where('surveyFrequency = ?', '1').each do |dailyUser|
			emailId=dailyUser.emailId
			PanelMailer.reminder_email(emailId).deliver_now
			puts "Daily Reminder Email sent to ", emailId, " at #{Time.now}\n"
		end
		
	end
end