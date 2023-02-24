# frozen_string_literal: true

require 'test_helper'

class Availabilities::AsPublicTest < ActionDispatch::IntegrationTest
  test 'get public machines availabilities if machines module is active' do
    start_date = Time.current.to_date
    end_date = 7.days.from_now.to_date

    get "/api/availabilities/public?start=#{start_date}&end=#{end_date}&timezone=Europe%2FParis&#{all_machines}"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct availabilities was returned
    availabilities = json_response(response.body)
    assert_not_empty availabilities, 'no availabilities were found'
    availabilities.each_with_index do |a, index|
      assert_not_nil a, "availability #{index} was unexpectedly nil"
      assert_equal 'machines', a[:available_type], "availability #{index} is not a machines availability"
      assert Time.zone.parse(a[:start]) > start_date, "availability #{index} starts before the requested period"
      assert Time.zone.parse(a[:end]) < end_date, "availability #{index} ends after the requested period"
    end
  end

  test 'get anymore machines availabilities if machines module is inactive' do
    Setting.set('machines_module', false)
    start_date = Time.current.to_date
    end_date = 7.days.from_now.to_date

    get "/api/availabilities/public?start=#{start_date}&end=#{end_date}&timezone=Europe%2FParis&#{all_machines}"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct availabilities was returned
    availabilities = json_response(response.body)
    assert_empty availabilities
  end

  test 'get public trainings availabilities' do
    start_date = Time.current.to_date
    end_date = 7.days.from_now.to_date

    get "/api/availabilities/public?start=#{start_date}&end=#{end_date}&timezone=Europe%2FParis&#{all_trainings}"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct availabilities was returned
    availabilities = json_response(response.body)
    assert_not_empty availabilities, 'no availabilities were found'
    availabilities.each_with_index do |a, index|
      assert_not_nil a, "availability #{index} was unexpectedly nil"
      assert_equal 'training', a[:available_type], "availability #{index} is not a training availability"
      assert Time.zone.parse(a[:start]) > start_date, "availability #{index} starts before the requested period"
      assert Time.zone.parse(a[:end]) < end_date, "availability #{index} ends after the requested period"
    end
  end

  test 'get public spaces availabilities' do
    start_date = Time.current.to_date
    end_date = 7.days.from_now.to_date

    get "/api/availabilities/public?start=#{start_date}&end=#{end_date}&timezone=Europe%2FParis&#{all_spaces}"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct availabilities was returned
    availabilities = json_response(response.body)
    assert_not_empty availabilities, 'no availabilities were found'
    availabilities.each_with_index do |a, index|
      assert_not_nil a, "availability #{index} was unexpectedly nil"
      assert_equal 'space', a[:available_type], "availability #{index} is not a space availability"
      assert Time.zone.parse(a[:start]) > start_date, "availability #{index} starts before the requested period"
      assert Time.zone.parse(a[:end]) < end_date, "availability #{index} ends after the requested period"
    end
  end

  test 'get public events availabilities' do
    start_date = 8.days.from_now.to_date
    end_date = 16.days.from_now.to_date

    get "/api/availabilities/public?start=#{start_date}&end=#{end_date}&timezone=Europe%2FParis&evt=true"

    # Check response format & status
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct availabilities was returned
    availabilities = json_response(response.body)
    assert_not_empty availabilities, 'no availabilities were found'
    availabilities.each_with_index do |a, index|
      assert_not_nil a, "availability #{index} was unexpectedly nil"
      assert_equal 'event', a[:available_type], "availability #{index} is not a event availability"
      assert Time.zone.parse(a[:start]) > start_date, "availability #{index} starts before the requested period"
      assert Time.zone.parse(a[:end]) < end_date, "availability #{index} ends after the requested period"
    end
  end

  private

  def all_machines
    Machine.all.map { |m| "m%5B%5D=#{m.id}" }.join('&')
  end

  def all_trainings
    Training.all.map { |m| "t%5B%5D=#{m.id}" }.join('&')
  end

  def all_spaces
    Space.all.map { |m| "s%5B%5D=#{m.id}" }.join('&')
  end
end
