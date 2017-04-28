class PanelMailer < ActionMailer::Base
  default from: "no-reply@ketsci.com"

  def welcome_email(user)
  	@user = user
  	# mail(to: @user.emailId, subject: 'Welcome Email')
  	mail(to: 'akhtarjameel@gmail.com', subject: 'Welcome Email')
  end
end
