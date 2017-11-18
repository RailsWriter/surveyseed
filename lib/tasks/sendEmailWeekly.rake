namespace :sendEmailWeekly do
	desc "ReminderMail"
	task :email_sender => :environment do
		print "Weekly Reminder Email started at #{Time.now}"
		puts

		User.where('surveyFrequency = ? AND emailId != ?', '7', "").each do |weeklyUser|
			emailId=weeklyUser.emailId
			print "Selected Weekly emailId: ", emailId
			puts
			PanelMailer.reminder_email(weeklyUser).deliver_now
			print "Weekly Reminder Email sent to ", emailId, " at #{Time.now}"
			puts
		end
		
	end
end