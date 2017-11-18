namespace :sendEmailDaily do
	desc "ReminderMail"
	task :email_sender => :environment do
		print "******** Daily Reminder Email Task Starting at #{Time.now} ************"
		puts

		User.where('surveyFrequency = ? AND emailId != ?', '1', "").each do |dailyUser|
			emailId=dailyUser.emailId
			print "Selected Daily emailId: ", emailId
			puts
			PanelMailer.reminder_email(dailyUser).deliver_now
			print "Daily Reminder Email sent to ", emailId, " at #{Time.now}"
			puts
		end	
	end
end