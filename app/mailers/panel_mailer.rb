class PanelMailer < ActionMailer::Base
  default from: "projectsmanagement@ketsci.com"

  def welcome_email(user)
  	@user = user
  	mail(to: @user.emailId, subject: 'Welcome to Ketsci. Complete surveys and win!')
  end

  def reminder_email(user)
  # def reminder_email(emailId)
  	@user = user
    emailId=@user.emailId
  	mail(to: emailId, subject: 'Complete Surveys to Win Rewards at Ketsci')
  	# mail(to: 'akhtarjameel@gmail.com', subject: 'Welcome Email')
  end
end
