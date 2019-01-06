class PanelMailer < ActionMailer::Base
  # default from: "projectsmanagement@ketsci.com"
  default from: "KETSCI <projectsmanagement@ketsci.com>", return_path: "projectsmanagement@ketsci.com"

  def welcome_email(user)
  	puts "*********************************************************************"
    print "ENV is ", Figaro.env.aws_smtp_username
    puts
    puts "*********************************************************************"
    @user = user
  	mail(to: @user.emailId, bcc: "projectsmanagement@ketsci.com", subject: 'Welcome to KETSCI! Complete surveys to win rewards!')
  end

  def reminder_email(user)
    puts "*********************************************************************"
    print "ENV is ", Figaro.env.aws_smtp_username
    puts
    puts "*********************************************************************"
    puts
  	@user = user
  	mail(to: @user.emailId, bcc: "projectsmanagement@ketsci.com", subject: 'Complete Surveys to win rewards!')
  end
end