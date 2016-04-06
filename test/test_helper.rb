ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'vcr'
require 'sidekiq/testing'
require 'minitest/reporters'

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
end

Sidekiq::Testing.inline!
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new({ color: true })]




class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...

  fixtures :all

  def json_response(body)
    JSON.parse(body, symbolize_names: true)
  end

  def default_headers
    { 'Accept' => Mime::JSON, 'Content-Type' => Mime::JSON.to_s }
  end

  def stripe_card_token
    Stripe::Token.create(
        :card => {
            :number => "4242424242424242",
            :exp_month => 4,
            :exp_year => DateTime.now.next_year.year,
            :cvc => "314"
        },
    ).id
  end
end

class ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!
end
