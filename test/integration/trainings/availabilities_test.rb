# frozen_string_literal: true

require 'test_helper'

module Trainings; end

class Trainings::AvailabilitiesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'get trainings availabilities list' do
    training = Training.find(1)
    get "/api/trainings/#{training.id}/availabilities"

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct training was returned
    result = json_response(response.body)
    assert_equal training.id, result[:id], 'training id does not match'
    assert_not_empty result[:availabilities], 'no training availabilities were returned'
  end
end
