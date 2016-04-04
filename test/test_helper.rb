ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new({ color: true })]


class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...

  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!
end
