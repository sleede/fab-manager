# frozen_string_literal: true

require 'test_helper'

class WalletsTest < ActionDispatch::IntegrationTest
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @vlonchamp = User.find_by(username: 'vlonchamp')
    login_as(@vlonchamp, scope: :user)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  test 'get my wallet' do
    get "/api/wallet/by_user/#{@vlonchamp.id}"
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    wallet = json_response(response.body)
    assert_equal @vlonchamp.wallet.invoicing_profile_id, wallet[:invoicing_profile_id]
    assert_equal @vlonchamp.wallet.amount, wallet[:amount]
  end

  test 'admin can get wallet by user id' do
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
    @user1 = User.first
    get "/api/wallet/by_user/#{@user1.id}"
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    wallet = json_response(response.body)
    assert_equal @user1.wallet.invoicing_profile_id, wallet[:invoicing_profile_id]
    assert_equal @user1.wallet.amount, wallet[:amount]
  end

  test 'cant get wallet of an user if not admin' do
    user5 = users(:user4)
    get "/api/wallet/by_user/#{user5.id}"
    assert_equal 403, response.status
  end

  test 'get all transactions of wallet' do
    w = @vlonchamp.wallet
    get "/api/wallet/#{w.id}/transactions"
    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    transactions = json_response(response.body)
    assert_equal w.wallet_transactions.count, transactions.size
    assert_equal wallet_transactions(:transaction1).id, transactions.first[:id]
  end

  test 'only admin and wallet owner can show their transactions' do
    user5 = users(:user4)
    get "/api/wallet/#{user5.wallet.id}/transactions"
    assert_equal 403, response.status
  end

  test 'admin can credit amount to a wallet' do
    admin = users(:user1)
    login_as(admin, scope: :user)
    w = @vlonchamp.wallet
    amount = 10.5
    expected_amount = w.amount + amount
    put "/api/wallet/#{w.id}/credit",
        params: { amount: amount }

    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    wallet = json_response(response.body)
    w.reload
    assert_equal w.amount, expected_amount
    assert_equal w.amount, wallet[:amount]

    # no refund invoices should have been generated
    assert_empty InvoiceItem.where(object: w.wallet_transactions.last)
  end

  test 'admin credit wallet with refund invoice generation' do
    admin = users(:user1)
    login_as(admin, scope: :user)
    w = @vlonchamp.wallet
    amount = 10
    avoir_date = Time.current.end_of_day
    expected_amount = w.amount + amount
    put "/api/wallet/#{w.id}/credit",
        params: {
          amount: amount,
          avoir: true,
          avoir_date: avoir_date,
          avoir_description: 'Some text'
        }

    assert_equal 200, response.status
    assert_match Mime[:json].to_s, response.content_type
    wallet = json_response(response.body)
    w.reload
    assert_equal w.amount, expected_amount
    assert_equal w.amount, wallet[:amount]

    # refund invoice must be generated
    item = InvoiceItem.find_by(object: w.wallet_transactions.last)
    invoice = item.invoice
    assert_equal amount, (invoice.total / 100.0), 'Avoir total does not match the amount credited to the wallet'
    assert_equal amount, (invoice.invoice_items.first.amount / 100.0), 'Invoice item amount does not match'
    assert_invoice_pdf invoice
  end
end
