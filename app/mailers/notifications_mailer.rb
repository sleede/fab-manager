class NotificationsMailer < NotifyWith::NotificationsMailer
  default :from => ENV['DEFAULT_MAIL_FROM']
  layout 'notifications_mailer'

  helper :application

  def helpers
    ActionController::Base.helpers
  end
end
