module Availabilities
  class AsAdminTest < ActionDispatch::IntegrationTest
    setup do
      admin = User.with_role(:admin).first
      login_as(admin, scope: :user)
    end

    test 'return availability by id' do
      a = Availability.take

      get "/api/availabilities/#{a.id}"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime::JSON, response.content_type

      # Check the correct availability was returned
      availability = json_response(response.body)
      assert_equal a.id, availability[:id], 'availability id does not match'
    end

    test 'get machine availabilities as admin' do
      m = Machine.find_by(slug: 'decoupeuse-vinyle')

      get "/api/availabilities/machines/#{m.id}"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime::JSON, response.content_type

      # Check the correct availabilities was returned
      availabilities = json_response(response.body)
      assert_not_empty availabilities, 'no availabilities were found'
      assert_not_nil availabilities[0], 'first availability was unexpectedly nil'
      assert_not_nil availabilities[0][:machine], "first availability's machine was unexpectedly nil"
      assert_equal m.id, availabilities[0][:machine][:id], "first availability's machine does not match the required machine"

      # Check that we din't get availabilities from the past
      availabilities.each do |a|
        assert_not a[:start] < DateTime.now, 'retrieved a slot in the past'
      end
    end

    test 'get calendar availabilities without spaces' do
      # disable spaces in application
      Rails.application.secrets.fablab_without_spaces = true

      # this simulates a fullCalendar (v2) call
      start_date = DateTime.now.utc.strftime('%Y-%m-%d')
      end_date = 7.days.from_now.utc.strftime('%Y-%m-%d')
      tz = Time.zone.tzinfo.name
      get "/api/availabilities?start=#{start_date}&end=#{end_date}&timezone=#{tz}&_=1487169767960"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime::JSON, response.content_type

      # Check the correct availabilities was returned
      availabilities = json_response(response.body)
      assert_not_empty availabilities, 'no availabilities were found'
      assert_not_nil availabilities[0], 'first availability was unexpectedly nil'

      assert_not availabilities.map {|a| a[:available_type] }.include?('space'), 'unexpected space availability instead that it was disabled'

      # re-enable spaces to keep tests ENV-safe
      Rails.application.secrets.fablab_without_spaces = false
    end

    test 'get calendar availabilities with spaces' do
      # this simulates a fullCalendar (v2) call
      start_date = DateTime.now.utc.strftime('%Y-%m-%d')
      end_date = 7.days.from_now.utc.strftime('%Y-%m-%d')
      tz = Time.zone.tzinfo.name
      get "/api/availabilities?start=#{start_date}&end=#{end_date}&timezone=#{tz}&_=1487169767960"

      # Check response format & status
      assert_equal 200, response.status
      assert_equal Mime::JSON, response.content_type

      # Check the correct availabilities was returned
      availabilities = json_response(response.body)
      assert_not_empty availabilities, 'no availabilities were found'
      assert_not_nil availabilities[0], 'first availability was unexpectedly nil'

      assert availabilities.map {|a| a[:available_type] }.include?('space'), 'space availability not found instead that it was enabled'
    end
  end
end

