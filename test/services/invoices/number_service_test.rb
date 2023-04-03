# frozen_string_literal: true

require 'test_helper'

class Invoices::NumberServiceTest < ActiveSupport::TestCase
  test 'invoice 1 numbers' do
    invoice = Invoice.find(1)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 1, reference
    assert_equal 1, order_number
    periodicity = Invoices::NumberService.number_periodicity(invoice)
    assert_equal 'month', periodicity
  end

  test 'invoice 2 numbers' do
    invoice = Invoice.find(2)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 2, reference
    assert_equal 2, order_number
    periodicity = Invoices::NumberService.number_periodicity(invoice, 'invoice_order-nb')
    assert_equal 'global', periodicity
  end

  test 'invoice 3 numbers' do
    invoice = Invoice.find(3)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 1, reference
    assert_equal 3, order_number
  end

  test 'invoice 4 numbers' do
    invoice = Invoice.find(4)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 2, reference
    assert_equal 4, order_number
  end

  test 'invoice 5 numbers' do
    invoice = Invoice.find(5)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 31, reference
    assert_equal 5, order_number
  end

  test 'invoice 6 numbers' do
    invoice = Invoice.find(6)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 41, reference
    assert_equal 6, order_number
  end

  test 'payment schedule 12 numbers' do
    schedule = PaymentSchedule.find(12)
    reference = Invoices::NumberService.number(schedule)
    order_number = Invoices::NumberService.number(schedule, 'invoice_order-nb')
    assert_equal 309, reference
    assert_equal 7, order_number
  end

  test 'payment schedule 13 numbers' do
    schedule = PaymentSchedule.find(13)
    reference = Invoices::NumberService.number(schedule)
    order_number = Invoices::NumberService.number(schedule, 'invoice_order-nb')
    assert_equal 310, reference
    assert_equal 8, order_number
  end

  test 'invoice 5811 numbers' do
    invoice = Invoice.find(5811)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 2, reference
    assert_equal 9, order_number
  end

  test 'invoice 5812 numbers' do
    invoice = Invoice.find(5812)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 4, reference
    assert_equal 5877, order_number
  end

  test 'invoice 5816 numbers' do
    invoice = Invoice.find(5816)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 2, reference
    assert_equal 5888, order_number
  end

  test 'invoice 5817 numbers' do
    invoice = Invoice.find(5817)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 4, reference
    assert_equal 5890, order_number
  end

  test 'invoice 5818 numbers' do
    invoice = Invoice.find(5818)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 6, reference
    assert_equal 5892, order_number
  end

  test 'invoice 5819 numbers' do
    invoice = Invoice.find(5819)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 8, reference
    assert_equal 5894, order_number
  end

  test 'invoice 5820 numbers' do
    invoice = Invoice.find(5820)
    reference = Invoices::NumberService.number(invoice)
    order_number = Invoices::NumberService.number(invoice, 'invoice_order-nb')
    assert_equal 10, reference
    assert_equal 5882, order_number
  end

  test 'daily periodicy' do
    Setting.set('invoice_reference', 'YYMDDddddddX[/VL]R[/A]S[/E]')
    invoice = sample_reservation_invoice(users(:user10), users(:user1))
    periodicity = Invoices::NumberService.number_periodicity(invoice)
    assert_equal 'day', periodicity
  end

  test 'monthly periodicy' do
    Setting.set('invoice_order-nb', 'MYYYYmmmm')
    invoice = sample_reservation_invoice(users(:user10), users(:user1))
    periodicity = Invoices::NumberService.number_periodicity(invoice, 'invoice_order-nb')
    assert_equal 'month', periodicity
  end

  test 'find document by number' do
    invoice = Invoices::NumberService.find_by_number(1, date: Time.zone.parse('2012-03-01'))
    assert_equal Invoice.first, invoice
  end
end
