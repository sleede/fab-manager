# frozen_string_literal: true

# Mailer configuration
class BaseMailer < ActionMailer::Base
  default from: ->(*) { Setting.get('mail_from') }
  layout 'notifications_mailer'

  helper :application

  def helpers
    ActionController::Base.helpers
  end
end
