# frozen_string_literal: true

require 'test_helper'

module Store; end

class Store::AdminPayOrderTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.find_by(username: 'admin')
    @pjproudhon = User.find_by(username: 'pjproudhon')
    @caisse_en_bois = Product.find_by(slug: 'caisse-en-bois')
    @panneaux = Product.find_by(slug: 'panneaux-de-mdf')
    @cart1 = Order.find_by(token: '0DKxbAOzSXRx-amXyhmDdg1666691976019')
    Cart::SetCustomerService.new(@admin).call(@cart1, @pjproudhon)
  end

  test 'admin pay user order by local with success' do
    login_as(@admin, scope: :user)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count

    post '/api/checkout/payment',
         params: {
           order_token: @cart1.token,
           customer_id: @pjproudhon.id
         }.to_json, headers: default_headers

    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert invoice_item.check_footprint

    # invoice assertions
    invoice = Invoice.last
    assert_invoice_pdf invoice

    assert @cart1.payment_gateway_object.blank?
    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: invoice)

    assert_equal @cart1.state, 'paid'
    assert_equal @cart1.payment_method, 'local'
    assert_equal @cart1.paid_total, 262_500

    stock_movement = @caisse_en_bois.product_stock_movements.last
    assert_equal stock_movement.stock_type, 'external'
    assert_equal stock_movement.reason, 'sold'
    assert_equal stock_movement.quantity, -5
    assert_equal stock_movement.order_item_id, @cart1.order_items.first.id

    stock_movement = @panneaux.product_stock_movements.last
    assert_equal stock_movement.stock_type, 'external'
    assert_equal stock_movement.reason, 'sold'
    assert_equal stock_movement.quantity, -2
    assert_equal stock_movement.order_item_id, @cart1.order_items.last.id

    activity = @cart1.order_activities.last
    assert_equal activity.activity_type, 'paid'
    assert_equal activity.operator_profile_id, @admin.invoicing_profile.id
  end

  test 'admin pay user offered order by local with success' do
    login_as(@admin, scope: :user)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count

    @cart1 = Cart::SetOfferService.new.call(@cart1, @caisse_en_bois, true)

    post '/api/checkout/payment',
         params: {
           order_token: @cart1.token,
           customer_id: @pjproudhon.id
         }.to_json, headers: default_headers

    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count

    # invoice_items assertions
    invoice_item = InvoiceItem.last

    assert invoice_item.check_footprint

    # invoice assertions
    invoice = Invoice.last
    assert_invoice_pdf invoice

    assert @cart1.payment_gateway_object.blank?
    assert invoice.payment_gateway_object.blank?
    assert_not invoice.total.blank?
    assert invoice.check_footprint

    # notification
    assert_not_empty Notification.where(attached_object: invoice)

    assert_equal @cart1.state, 'paid'
    assert_equal @cart1.payment_method, 'local'
    assert_equal @cart1.paid_total, 1_000

    stock_movement = @caisse_en_bois.product_stock_movements.last
    assert_equal stock_movement.stock_type, 'external'
    assert_equal stock_movement.reason, 'sold'
    assert_equal stock_movement.quantity, -5
    assert_equal stock_movement.order_item_id, @cart1.order_items.first.id

    stock_movement = @panneaux.product_stock_movements.last
    assert_equal stock_movement.stock_type, 'external'
    assert_equal stock_movement.reason, 'sold'
    assert_equal stock_movement.quantity, -2
    assert_equal stock_movement.order_item_id, @cart1.order_items.last.id

    activity = @cart1.order_activities.last
    assert_equal activity.activity_type, 'paid'
    assert_equal activity.operator_profile_id, @admin.invoicing_profile.id
  end

  test 'admin pay user order by wallet with success' do
    login_as(@admin, scope: :user)

    service = WalletService.new(user: @admin, wallet: @pjproudhon.wallet)
    service.credit(@cart1.total / 100)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    post '/api/checkout/payment',
         params: {
           order_token: @cart1.token,
           customer_id: @pjproudhon.id
         }.to_json, headers: default_headers

    @pjproudhon.wallet.reload
    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal @cart1.state, 'paid'
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
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

  test 'admin pay user order by wallet and coupon with success' do
    login_as(@admin, scope: :user)

    service = WalletService.new(user: @admin, wallet: @pjproudhon.wallet)
    service.credit(@cart1.total / 100)

    invoice_count = Invoice.count
    invoice_items_count = InvoiceItem.count
    users_credit_count = UsersCredit.count
    wallet_transactions_count = WalletTransaction.count

    post '/api/checkout/payment',
         params: {
           order_token: @cart1.token,
           customer_id: @pjproudhon.id,
           coupon_code: 'GIME3EUR'
         }.to_json, headers: default_headers

    @pjproudhon.wallet.reload
    @cart1.reload

    # general assertions
    assert_equal 200, response.status
    assert_equal @cart1.state, 'paid'
    assert_equal invoice_count + 1, Invoice.count
    assert_equal invoice_items_count + 2, InvoiceItem.count
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
    assert_equal @cart1.wallet_amount, 262_200
    assert_equal 2622, transaction.amount
  end
end
