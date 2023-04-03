# frozen_string_literal: true

require 'test_helper'

module Store; end

class Store::UserPayOrderTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    @pjproudhon = User.find_by(username: 'pjproudhon')
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
    @cart1 = Order.find_by(token: 'KbSmmD_gi9w_CrpwtK9OwA1666687433963')
  end

  test 'user pay order by cart with success' do
    login_as(@pjproudhon, scope: :user)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count

    VCR.use_cassette('store_order_pay_by_cart_success') do
      post '/api/checkout/payment',
           params: {
             payment_id: stripe_payment_method,
             order_token: @cart1.token
           }.to_json, headers: default_headers
    end

    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert invoice_item.check_footprint

    # invoice assertions
    invoice = Invoice.last
    assert_invoice_pdf invoice

    assert_not invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: invoice)

    assert_equal @cart1.state, 'paid'
    assert_equal @cart1.payment_method, 'card'
    assert_equal @cart1.paid_total, 500
    stock_movement = @panneaux.product_stock_movements.last
    assert_equal stock_movement.stock_type, 'external'
    assert_equal stock_movement.reason, 'sold'
    assert_equal stock_movement.quantity, -1
    assert_equal stock_movement.order_item_id, @cart1.order_items.first.id
    activity = @cart1.order_activities.last
    assert_equal activity.activity_type, 'paid'
    assert_equal activity.operator_profile_id, @pjproudhon.invoicing_profile.id
  end

  test 'user pay order by cart and wallet with success' do
    login_as(@pjproudhon, scope: :user)

    service = WalletService.new(user: @admin, wallet: @pjproudhon.wallet)
    service.credit(1)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    VCR.use_cassette('store_order_pay_by_cart_and_wallet_success') do
      post '/api/checkout/payment',
           params: {
             payment_id: stripe_payment_method,
             order_token: @cart1.token
           }.to_json, headers: default_headers
    end

    @pjproudhon.wallet.reload
    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert invoice_item.check_footprint

    # invoice assertions
    invoice = Invoice.last
    assert_invoice_pdf invoice

    assert_not @cart1.payment_gateway_object.blank?
    assert_not invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # invoice notification
    assert_not_empty Notification.where(attached_object: invoice)

    # order notification
    assert_not_nil Notification.find_by(
      notification_type_id: NotificationType.find_by(name: 'notify_admin_order_is_paid'),
      attached_object: @cart1.order_activities.last
    )

    assert_equal @cart1.state, 'paid'
    assert_equal @cart1.payment_method, 'card'
    assert_equal @cart1.paid_total, 400
    assert_equal users_credit_count, UsersCredit.count
    assert_equal wallet_transactions_count + 1, WalletTransaction.count

    # wallet
    assert_equal 0, @pjproudhon.wallet.amount
    assert_equal 2, @pjproudhon.wallet.wallet_transactions.count
    transaction = @pjproudhon.wallet.wallet_transactions.last
    assert_equal 'debit', transaction.transaction_type
    assert_equal @cart1.paid_total, 400
    assert_equal @cart1.wallet_amount / 100.0, transaction.amount
    assert_equal @cart1.payment_method, 'card'
    assert_equal @cart1.wallet_transaction_id, transaction.id
    assert_equal invoice.wallet_amount / 100.0, transaction.amount
  end

  test 'user pay order by wallet with success' do
    login_as(@pjproudhon, scope: :user)

    service = WalletService.new(user: @admin, wallet: @pjproudhon.wallet)
    service.credit(@cart1.total / 100)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    post '/api/checkout/payment',
         params: {
           order_token: @cart1.token
         }.to_json, headers: default_headers

    @pjproudhon.wallet.reload
    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal @cart1.state, 'paid'
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal wallet_transactions_count + 1, WalletTransaction.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert invoice_item.check_footprint

    # invoice assertions
    invoice = Invoice.last
    assert_invoice_pdf invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: invoice)

    # wallet
    assert_equal 0, @pjproudhon.wallet.amount
    assert_equal 2, @pjproudhon.wallet.wallet_transactions.count
    transaction = @pjproudhon.wallet.wallet_transactions.last
    assert_equal 'debit', transaction.transaction_type
    assert_equal @cart1.paid_total, 0
    assert_equal @cart1.wallet_amount / 100.0, transaction.amount
    assert_equal @cart1.payment_method, 'wallet'
    assert_equal @cart1.wallet_transaction_id, transaction.id
    assert_equal invoice.wallet_amount / 100.0, transaction.amount
  end

  test 'user pay order by wallet and coupon with success' do
    login_as(@pjproudhon, scope: :user)

    service = WalletService.new(user: @admin, wallet: @pjproudhon.wallet)
    service.credit(@cart1.total / 100)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    post '/api/checkout/payment',
         params: {
           order_token: @cart1.token,
           coupon_code: 'GIME3EUR'
         }.to_json, headers: default_headers

    @pjproudhon.wallet.reload
    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal @cart1.state, 'paid'
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 1, InvoiceItem.count
    assert_equal users_credit_count, UsersCredit.count
    assert_equal wallet_transactions_count + 1, WalletTransaction.count
    assert_equal Coupon.find_by(code: 'GIME3EUR').id, @cart1.coupon_id

    # invoice_items assertions
    invoice_item = InvoiceItem.last
    assert invoice_item.check_footprint

    # invoice assertions
    invoice = Invoice.last
    assert_invoice_pdf invoice

    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: invoice)

    # wallet
    assert_equal 3, @pjproudhon.wallet.amount
    assert_equal 2, @pjproudhon.wallet.wallet_transactions.count
    transaction = @pjproudhon.wallet.wallet_transactions.last
    assert_equal 'debit', transaction.transaction_type
    assert_equal @cart1.paid_total, 0
    assert_equal @cart1.wallet_amount, 200
    assert_equal 2, transaction.amount
  end
end
