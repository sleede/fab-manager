# frozen_string_literal: true

require 'test_helper'

module Credits; end

class Credits::TrainingTest < ActionDispatch::IntegrationTest
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'create machine credit' do
    # First, we create a new credit
    post '/api/credits',
         params: {
           credit: {
             creditable_id: 5,
             creditable_type: 'Machine',
             hours: 1,
             plan_id: 1
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the credit was created correctly
    credit = json_response(response.body)
    c = Credit.where(id: credit[:id]).first
    assert_not_nil c, 'Credit was not created in database'

    # Check that 1 hour is associated with the credit
    assert_equal 1, c.hours
  end

  test 'update a credit' do
    put '/api/credits/13',
        params: {
          credit: {
            creditable_id: 4,
            creditable_type: 'Machine',
            hours: 5,
            plan_id: 3
          }
        }.to_json,
        headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the credit was correctly updated
    credit = json_response(response.body)
    assert_equal 13, credit[:id]
    c = Credit.find(credit[:id])
    assert c.updated_at > 1.minute.ago

    assert_equal 5, c.hours
  end
end
