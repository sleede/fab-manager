# frozen_string_literal: true

require 'test_helper'

class PaymentDocumentServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.find_by(username: 'admin')
    @acamus = User.find_by(username: 'acamus')
    @machine = Machine.first
    # From the fixtures,
    # - invoice_reference = YYMMmmmX[/VL]R[/A]
    # - invoice_order-nb = nnnnnn-MM-YY
  end

  test 'invoice for local payment' do
    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}001", invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", invoice.order_number
  end

  test 'invoice with custom format' do
    travel_to(Time.current.beginning_of_month)
    Setting.set('invoice_reference', 'YYYYMMMDdddddX[/VL]R[/A]S[/E]')
    Setting.set('invoice_order-nb', 'yyyy-YYYY')
    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%Y%^b%-d')}00001", invoice.reference
    assert_equal "0001-#{Time.current.strftime('%Y')}", invoice.order_number
    travel_back
  end

  test 'invoice with other custom format' do
    travel_to(Time.current.beginning_of_year)
    Setting.set('invoice_reference', 'YYMDDyyyyX[/VL]R[/A]S[/E]')
    Setting.set('invoice_order-nb', 'DMYYYYnnnnnn')
    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%-m%d')}0001", invoice.reference
    assert_equal "#{Time.current.strftime('%-d%-m%Y')}000018", invoice.order_number
    travel_back
  end

  test 'invoice for online card payment' do
    invoice = sample_reservation_invoice(@acamus, @acamus)
    assert_equal "#{Time.current.strftime('%y%m')}001/VL", invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", invoice.order_number
  end

  test 'refund' do
    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}001", invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", invoice.order_number

    refund = invoice.build_avoir(payment_method: 'wallet', invoice_items_ids: invoice.invoice_items.map(&:id))
    refund.save
    refund.reload
    assert_equal "#{Time.current.strftime('%y%m')}002/A", refund.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", refund.order_number
  end

  test 'payment schedule' do
    Setting.set('invoice_reference', 'YYMMmmmX[/VL]R[/A]S[/E]')
    schedule = sample_schedule(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}001/E", schedule.reference
    first_item = schedule.ordered_items.first
    assert_equal "#{Time.current.strftime('%y%m')}001", first_item.invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", first_item.invoice.order_number
    second_item = schedule.ordered_items[1]
    PaymentScheduleService.new.generate_invoice(second_item, payment_method: 'check')
    assert_equal "#{Time.current.strftime('%y%m')}002", second_item.invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", second_item.invoice.order_number
    third_item = schedule.ordered_items[2]
    PaymentScheduleService.new.generate_invoice(third_item, payment_method: 'check')
    assert_equal "#{Time.current.strftime('%y%m')}003", third_item.invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", third_item.invoice.order_number
    fourth_item = schedule.ordered_items[3]
    PaymentScheduleService.new.generate_invoice(fourth_item, payment_method: 'check')
    assert_equal "#{Time.current.strftime('%y%m')}004", fourth_item.invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", fourth_item.invoice.order_number
    fifth_item = schedule.ordered_items[2]
    PaymentScheduleService.new.generate_invoice(fifth_item, payment_method: 'check')
    assert_equal "#{Time.current.strftime('%y%m')}005", fifth_item.invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", fifth_item.invoice.order_number
  end

  test 'order' do
    cart = Cart::FindOrCreateService.new(users(:user_2)).call(nil)
    cart = Cart::AddItemService.new.call(cart, Product.find_by(slug: 'panneaux-de-mdf'), 1)
    Checkout::PaymentService.new.payment(cart, @admin, nil)
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", cart.reference # here reference = order number
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", cart.invoice.order_number
    assert_equal "#{Time.current.strftime('%y%m')}001", cart.invoice.reference
  end

  test 'multiple items logical sequence' do
    Setting.set('invoice_reference', 'YYMMmmmX[/VL]R[/A]S[/E]')

    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}001", invoice.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", invoice.order_number

    refund = invoice.build_avoir(payment_method: 'wallet', invoice_items_ids: invoice.invoice_items.map(&:id))
    refund.save
    refund.reload
    assert_equal "#{Time.current.strftime('%y%m')}002/A", refund.reference
    assert_equal "000023-#{Time.current.strftime('%m-%y')}", refund.order_number

    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}003", invoice.reference
    assert_equal "000024-#{Time.current.strftime('%m-%y')}", invoice.order_number

    invoice = sample_reservation_invoice(@acamus, @acamus)
    assert_equal "#{Time.current.strftime('%y%m')}004/VL", invoice.reference
    assert_equal "000025-#{Time.current.strftime('%m-%y')}", invoice.order_number

    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}005", invoice.reference
    assert_equal "000026-#{Time.current.strftime('%m-%y')}", invoice.order_number

    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}006", invoice.reference
    assert_equal "000027-#{Time.current.strftime('%m-%y')}", invoice.order_number

    invoice = sample_reservation_invoice(@acamus, @acamus)
    assert_equal "#{Time.current.strftime('%y%m')}007/VL", invoice.reference
    assert_equal "000028-#{Time.current.strftime('%m-%y')}", invoice.order_number

    invoice = sample_reservation_invoice(@acamus, @acamus)
    assert_equal "#{Time.current.strftime('%y%m')}008/VL", invoice.reference
    assert_equal "000029-#{Time.current.strftime('%m-%y')}", invoice.order_number

    refund = invoice.build_avoir(payment_method: 'wallet', invoice_items_ids: invoice.invoice_items.map(&:id))
    refund.save
    refund.reload
    assert_equal "#{Time.current.strftime('%y%m')}009/A", refund.reference
    assert_equal "000029-#{Time.current.strftime('%m-%y')}", refund.order_number

    invoice = sample_reservation_invoice(@acamus, @acamus)
    assert_equal "#{Time.current.strftime('%y%m')}010/VL", invoice.reference
    assert_equal "000030-#{Time.current.strftime('%m-%y')}", invoice.order_number

    invoice2 = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}011", invoice2.reference
    assert_equal "000031-#{Time.current.strftime('%m-%y')}", invoice2.order_number

    refund = invoice.build_avoir(payment_method: 'wallet', invoice_items_ids: invoice.invoice_items.map(&:id))
    refund.save
    refund.reload
    assert_equal "#{Time.current.strftime('%y%m')}012/A", refund.reference
    assert_equal "000030-#{Time.current.strftime('%m-%y')}", refund.order_number

    refund = invoice2.build_avoir(payment_method: 'wallet', invoice_items_ids: invoice.invoice_items.map(&:id))
    refund.save
    refund.reload
    assert_equal "#{Time.current.strftime('%y%m')}013/A", refund.reference
    assert_equal "000031-#{Time.current.strftime('%m-%y')}", refund.order_number

    schedule = sample_schedule(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}001/E", schedule.reference
    assert_equal "#{Time.current.strftime('%y%m')}014", schedule.ordered_items.first.invoice.reference
    assert_equal "000032-#{Time.current.strftime('%m-%y')}", schedule.ordered_items.first.invoice.order_number

    schedule = sample_schedule(users(:user_2), users(:user_2))
    assert_equal "#{Time.current.strftime('%y%m')}002/E", schedule.reference
    assert_equal "#{Time.current.strftime('%y%m')}015/VL", schedule.ordered_items.first.invoice.reference
    assert_equal "000033-#{Time.current.strftime('%m-%y')}", schedule.ordered_items.first.invoice.order_number

    invoice = sample_reservation_invoice(@acamus, @acamus)
    assert_equal "#{Time.current.strftime('%y%m')}016/VL", invoice.reference
    assert_equal "000034-#{Time.current.strftime('%m-%y')}", invoice.order_number

    cart = Cart::FindOrCreateService.new(users(:user_2)).call(nil)
    cart = Cart::AddItemService.new.call(cart, Product.find_by(slug: 'panneaux-de-mdf'), 1)
    Checkout::PaymentService.new.payment(cart, @admin, nil)
    assert_equal "000035-#{Time.current.strftime('%m-%y')}", cart.reference # here reference = order number
    assert_equal "000035-#{Time.current.strftime('%m-%y')}", cart.invoice.order_number
    assert_equal "#{Time.current.strftime('%y%m')}017", cart.invoice.reference

    cart = Cart::FindOrCreateService.new(users(:user_2)).call(nil)
    cart = Cart::AddItemService.new.call(cart, Product.find_by(slug: 'panneaux-de-mdf'), 1)
    Checkout::PaymentService.new.payment(cart, @admin, nil)
    assert_equal "000036-#{Time.current.strftime('%m-%y')}", cart.reference # here reference = order number
    assert_equal "000036-#{Time.current.strftime('%m-%y')}", cart.invoice.order_number
    assert_equal "#{Time.current.strftime('%y%m')}018", cart.invoice.reference

    invoice = sample_reservation_invoice(@acamus, @admin)
    assert_equal "#{Time.current.strftime('%y%m')}019", invoice.reference
    assert_equal "000037-#{Time.current.strftime('%m-%y')}", invoice.order_number
  end
end
