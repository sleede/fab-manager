# frozen_string_literal: true

# Override the default Devise settings for emails notifications
class OverwrittenDeviseMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  default from: ->(*) { Setting.get('mail_from') }
end
