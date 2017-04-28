# Preview all emails at http://localhost:3000/rails/mailers/panel_mailer
class PanelMailerPreview < ActionMailer::Preview
def welcome_mail_preview
    PanelMailer.welcome_email(User.first)
  end
end
