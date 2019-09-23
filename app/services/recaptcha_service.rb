# frozen_string_literal: true

# Provides methods to verify the client captcha on Google's services
class RecaptchaService
  class << self
    def verify(client_response)
      return { 'success' => true } unless recaptcha_enabled?

      require 'uri'
      require 'net/http'

      data = { secret: secret_key, response: client_response }
      url = URI.parse('https://www.google.com/recaptcha/api/siteverify')
      res = Net::HTTP.post_form(url, data)

      JSON.parse(res&.body)
    end

    def recaptcha_enabled?
      secret_key.present? && site_key.present?
    end

    def secret_key
      Rails.application.secrets.recaptcha_secret_key
    end

    def site_key
      Rails.application.secrets.recaptcha_site_key
    end
  end
end