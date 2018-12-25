# This script sends emails to Panelists in Production environment.

begin
  timetorepeat = true
  #rm /tmp/sendEmailCronAWS.log
  # sudo bundle exec rake sendEmailDaily:email_sender RAILS_ENV=production --silent >> /tmp/sendEmailCronAWS.log
    
  print "******** sendReminderEmailToPanelists Script Starting at #{Time.now} ************"
  puts

  User.where('emailId != ?', "").each do |dailyUser|
    begin
      emailId=dailyUser.emailId
      print "Selected Daily emailId: ", emailId
      puts
      if (emailId == 'akhtarjameel@gmail.com') || (emailId == 'mohsinashakir@gmail.com') || (emailId == 'dasriharsha@gmail.com') || (emailId == 'akhtarjameel@yahoo.com') then
        begin
          PanelMailer.reminder_email(dailyUser).deliver_now
          print "Daily Reminder Email sent to ", emailId, " at #{Time.now}"
          puts
          rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
            print "Problem sending Daily Reminder mail to ", emailId, " due to message: ", e.message
            puts
        end
      else
      end
    end
  end 

  print "UTC time ", Time.now
  puts	
  # print "Local time ", Time.now-7*60*60 # Mar-Nov DST
  print "Local time ", Time.now-8*60*60 # Nov - Mar PST	
  puts
  puts "Sent Emails To Panelists. Going to sleep for 1 day"
  # sleep (1.days)
  sleep (24.hours)
end while timetorepeat