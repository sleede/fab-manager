# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::InvoicesTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all invoices' do
    get '/open_api/v1/invoices', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all invoices with pagination' do
    get '/open_api/v1/invoices?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all invoices for a user' do
    get '/open_api/v1/invoices?user_id=3', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'list all invoices for a user with pagination' do
    get '/open_api/v1/invoices?user_id=3&page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'download an invoice' do
    get '/open_api/v1/invoices/3/download', headers: open_api_headers(@token)
    assert_response :success
    assert_match /^inline; filename=/, response.headers['Content-Disposition']
  end
end
