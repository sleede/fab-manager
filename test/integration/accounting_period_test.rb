# frozen_string_literal: true

class AccountingPeriodTest < ActionDispatch::IntegrationTest

  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin closes an accounting period' do
    start_at = '2012-01-01T00:00:00.000Z'
    end_at = '2012-12-31T00:00:00.000Z'

    post '/api/accounting_periods',
         {
           accounting_period: {
             start_at: start_at,
             end_at: end_at
           }
         }.to_json, default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the correct period was closed successfully
    period = json_response(response.body)
    accounting_period = AccountingPeriod.find(period[:id])
    assert_dates_equal start_at.to_date, period[:start_at]
    assert_dates_equal end_at.to_date, period[:end_at]

    # Check archive file was created
    assert FileTest.exists? accounting_period.archive_file

    # Check archive matches
    archive = File.read(accounting_period.archive_file)
    archive_json = JSON.parse(archive)
    invoices = Invoice.where(
      'created_at >= :start_date AND created_at <= :end_date',
      start_date: start_at.to_datetime, end_date: end_at.to_datetime
    )
    assert_equal invoices.count, archive_json.count
  end

end
