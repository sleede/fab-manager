# frozen_string_literal: true

require 'test_helper'

class AccountingPeriodTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin closes an accounting period' do
    start_at = '2012-01-01T00:00:00.000Z'
    end_at = '2012-12-31T00:00:00.000Z'

    post '/api/accounting_periods',
         params: {
           accounting_period: {
             start_at: start_at,
             end_at: end_at
           }
         }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct period was closed successfully
    period = json_response(response.body)
    accounting_period = AccountingPeriod.find(period[:id])
    assert_dates_equal start_at.to_date, period[:start_at]
    assert_dates_equal end_at.to_date, period[:end_at]

    # Check archive file was created
    assert_archive accounting_period
  end

  test 'admin tries to close a too long period' do
    start_at = '2012-01-01T00:00:00.000Z'
    end_at = '2014-12-31T00:00:00.000Z'
    diff = (end_at.to_date - start_at.to_date).to_i

    post '/api/accounting_periods',
         params: {
           accounting_period: {
             start_at: start_at,
             end_at: end_at
           }
         }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 422, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # check the error
    assert_match(/#{I18n.t('errors.messages.invalid_duration', **{ DAYS: diff })}/, response.body)
  end

  test 'admin tries to close an overlapping period' do
    start_at = '2014-12-01T00:00:00.000Z'
    end_at = '2015-02-27T00:00:00.000Z'

    post '/api/accounting_periods',
         params: {
           accounting_period: {
             start_at: start_at,
             end_at: end_at
           }
         }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 422, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # check the error
    assert_match(/#{I18n.t('errors.messages.cannot_overlap')}/, response.body)
  end

  test 'admin tries to close today' do
    start_at = Time.current.beginning_of_day.iso8601
    end_at = Time.current.end_of_day.iso8601

    post '/api/accounting_periods',
         params: {
           accounting_period: {
             start_at: start_at,
             end_at: end_at
           }
         }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 422, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # check the error
    assert_match(/#{I18n.t('errors.messages.must_be_in_the_past')}/, response.body)
  end

  test 'get the end of the last closed period' do
    get '/api/accounting_periods/last_closing_end'

    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    resp = json_response(response.body)

    period_end = AccountingPeriod.first.end_at
    assert_equal (period_end + 1.day).to_s, resp[:last_end_date]
  end

  test 'download the archive' do
    period_id = AccountingPeriod.first.id
    get "/api/accounting_periods/#{period_id}/archive"

    assert_match(/^attachment; filename=/, response.headers['Content-Disposition'])
  end

  test 'list all periods' do
    get '/api/accounting_periods'
    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the periods
    periods = json_response(response.body)
    assert_equal AccountingPeriod.count, periods.length
  end
end
