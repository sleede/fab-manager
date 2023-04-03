# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  Devise::Mailer.class_eval do
    helper :application
  end
end
