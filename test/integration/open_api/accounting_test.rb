# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::AccountingTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all accounting lines' do
    get '/open_api/v1/accounting', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    lines = json_response(response.body)
    assert_not_empty lines[:lines]
    assert_not_nil lines[:lines][0][:id]
    assert_not_empty lines[:lines][0][:line_type]
    assert_not_empty lines[:lines][0][:journal_code]
    assert_not_empty lines[:lines][0][:date]
    assert_not_empty lines[:lines][0][:account_code]
    assert_not_empty lines[:lines][0][:account_label]
    assert_nil lines[:lines][0][:analytical_code]
    assert_not_nil lines[:lines][0][:invoice]
    assert_not_empty lines[:lines][0][:invoice][:reference]
    assert_not_nil lines[:lines][0][:invoice][:id]
    assert_not_empty lines[:lines][0][:invoice][:label]
    assert_not_empty lines[:lines][0][:invoice][:url]
    assert_not_nil lines[:lines][0][:user][:invoicing_profile_id]
    assert_not_nil lines[:lines][0][:user][:external_id]
    assert_not_nil lines[:lines][0][:debit]
    assert_not_nil lines[:lines][0][:credit]
    assert_not_empty lines[:lines][0][:currency]
    assert_not_empty lines[:lines][0][:summary]
    assert_equal 'built', lines[:status]
  end

  test 'list all accounting lines with pagination' do
    get '/open_api/v1/accounting?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    lines = json_response(response.body)
    assert_equal 5, lines[:lines].count
  end

  test 'list all accounting lines with dates filtering' do
    get '/open_api/v1/accounting?after=2022-09-01T00:00:00+02:00&before=2022-09-30T23:59:59+02:00', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    lines = json_response(response.body)
    assert lines[:lines].count.positive?
    assert(lines[:lines].all? do |line|
      date = DateTime.parse(line[:date])
      date >= '2022-09-01'.to_date && date <= '2022-09-30'.to_date
    end)
  end

  test 'list all accounting lines with invoices filtering' do
    get '/open_api/v1/accounting?invoice_id=[1,2,3]', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    lines = json_response(response.body)
    assert lines[:lines].count.positive?
    assert(lines[:lines].all? { |line| [1, 2, 3].include?(line[:invoice][:id]) })
  end

  test 'list all accounting lines with type filtering' do
    get '/open_api/v1/accounting?type=[client,vat]', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    lines = json_response(response.body)
    assert lines[:lines].count.positive?
    assert(lines[:lines].all? { |line| %w[client vat].include?(line[:line_type]) })
  end

  test 'list all accounting client lines have payment details' do
    get '/open_api/v1/accounting?type=client', headers: open_api_headers(@token)
    assert_response :success
    assert_equal Mime[:json], response.content_type

    card_code = Setting.get('accounting_card_client_code')
    wallet_code = Setting.get('accounting_wallet_client_code')
    other_code = Setting.get('accounting_other_client_code')

    lines = json_response(response.body)
    assert lines[:lines].count.positive?
    assert(lines[:lines].all? { |line| line[:line_type] == 'client' })
    assert(lines[:lines].all? { |line| !line[:invoice][:payment_details].nil? })
    assert(lines[:lines].filter { |line| line[:account_code] == card_code }
                        .none? { |line| line[:invoice][:payment_details][:gateway_object_id].nil? })
    assert(lines[:lines].filter { |line| line[:account_code] == card_code }
                        .none? { |line| line[:invoice][:payment_details][:gateway_object_type].nil? })
    assert(lines[:lines].filter { |line| line[:account_code] == wallet_code }
                        .none? { |line| line[:invoice][:payment_details][:wallet_transaction_id].nil? })
    assert(lines[:lines].filter { |line| line[:account_code] == other_code }
                        .all? { |line| line[:invoice][:payment_details].empty? })
  end
end
