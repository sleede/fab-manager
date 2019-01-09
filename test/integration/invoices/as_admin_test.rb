# frozen_string_literal: true

class InvoicesTest < ActionDispatch::IntegrationTest

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'admin list invoices' do

    post '/api/invoices/list', { query: {
      number: '',
      customer: '',
      date: nil,
      order_by: '-reference',
      page: 1,
      size: 20 # test db may have < 20 invoices
    } }.to_json, default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check that we have all invoices
    invoices = json_response(response.body)
    assert_equal Invoice.count, invoices.size, 'some invoices are missing'

    # Check that invoices are ordered by reference
    assert_equal '1604002', invoices.first[:reference]
    assert_equal '1203001', invoices.last[:reference]
  end

end
