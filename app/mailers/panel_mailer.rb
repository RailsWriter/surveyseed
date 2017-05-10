class PanelMailer < ActionMailer::Base
  default from: "projectsmanagement@ketsci.com"

  def welcome_email(user)
  	@user = user
  	# mail(to: @user.emailId, subject: 'Welcome Email')
  	mail(to: 'akhtarjameel@gmail.com', subject: 'Welcome Email')
  end
end
