class PanelMailer < ActionMailer::Base
  # default from: "projectsmanagement@ketsci.com"
  default from: "KETSCI <projectsmanagement@ketsci.com>", return_path: "projectsmanagement@ketsci.com"

  def welcome_email(user)
  	@user = user
  	mail(to: @user.emailId, subject: 'Welcome to KETSCI. Complete surveys to win rewards!')
  end

  def reminder_email(user)
  	@user = user
  	mail(to: @user.emailId, subject: 'Complete Surveys to win rewards!')
  end
end