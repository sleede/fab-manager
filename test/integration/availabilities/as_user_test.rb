# frozen_string_literal: true

require 'test_helper'

class Availabilities::AsUserTest < ActionDispatch::IntegrationTest
  setup do
    user = User.find_by(username: 'kdumas')
    login_as(user, scope: :user)
  end

  test 'get machine availabilities as user' do
    m = Machine.find_by(slug: 'decoupeuse-vinyle')

    # this simulates a fullCalendar (v2) call
    start_date = Time.current.utc.strftime('%Y-%m-%d')
    end_date = 7.days.from_now.utc.strftime('%Y-%m-%d')
    tz = Time.zone.tzinfo.name

    get "/api/availabilities/machines/#{m.id}?start=#{start_date}&end=#{end_date}&timezone=#{tz}&_=1800145267413"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct availabilities was returned
    availabilities = json_response(response.body)
    assert_not_empty availabilities, 'no availabilities were found'
    assert_not_nil availabilities[0], 'first availability was unexpectedly nil'
    assert_not_nil availabilities[0][:machine], "first availability's machine was unexpectedly nil"
    assert_equal m.id, availabilities[0][:machine][:id], "first availability's machine does not match the required machine"

    availabilities.each do |a|
      # Check that we din't get availabilities from the past
      assert_not a[:start] < Time.current, 'retrieved a slot in the past'
      # Check that we don't get availabilities in more than a month
      assert_not a[:start] > 1.month.from_now, 'retrieved a slot in more than 1 month for user who has no yearly subscription'
    end
  end
end
