# frozen_string_literal: true

require 'test_helper'
require 'pay_zen/service'

class PayZen::ServiceTest < ActiveSupport::TestCase
  setup do
    @service = PayZen::Service.new
  end

  test '#rrule' do
    ps = payment_schedules(:payment_schedule_12)

    first_due_date = ps.ordered_items.first.due_date

    first_date = first_due_date
    assert_equal "RRULE:FREQ=MONTHLY;BYMONTHDAY=14;COUNT=12", @service.rrule(ps, first_date)

    assert_equal "RRULE:FREQ=MONTHLY;BYMONTHDAY=14;COUNT=11", @service.rrule(ps, first_date, -1)

    first_date = first_due_date + 3.days
    assert_equal "RRULE:FREQ=MONTHLY;BYMONTHDAY=17;COUNT=12", @service.rrule(ps, first_date)

    first_due_date = first_due_date.change(month: 7)

    first_date = first_due_date.change(day: 28)
    assert_equal "RRULE:FREQ=MONTHLY;BYMONTHDAY=28;COUNT=12", @service.rrule(ps, first_date)

    first_date = first_due_date.change(day: 29)
    assert_equal "RRULE:FREQ=MONTHLY;BYMONTHDAY=28,29;BYSETPOS=-1;COUNT=12", @service.rrule(ps, first_date)

    first_date = first_due_date.change(day: 30)
    assert_equal "RRULE:FREQ=MONTHLY;BYMONTHDAY=28,29,30;BYSETPOS=-1;COUNT=12", @service.rrule(ps, first_date)

    first_date = first_due_date.change(day: 31)
    assert_equal "RRULE:FREQ=MONTHLY;BYMONTHDAY=28,29,30,31;BYSETPOS=-1;COUNT=12", @service.rrule(ps, first_date)
  end

  def format_transaction(operation_type:, expected_capture_date:)
    { "operationType" => operation_type, "transactionDetails" => { "paymentMethodDetails" => { "expectedCaptureDate" => expected_capture_date } } }
  end

  test "#find_transaction_by_payment_schedule_item" do
    ps = payment_schedules(:payment_schedule_12)

    payment_schedule_item = ps.ordered_items.first

    expected_capture_date = payment_schedule_item.due_date.iso8601
    transactions = [format_transaction(operation_type: "DEBIT", expected_capture_date: expected_capture_date)]

    assert @service.find_transaction_by_payment_schedule_item(transactions, payment_schedule_item)

    expected_capture_date = (payment_schedule_item.due_date - 1.day).iso8601
    transactions = [format_transaction(operation_type: "DEBIT", expected_capture_date: expected_capture_date)]

    assert @service.find_transaction_by_payment_schedule_item(transactions, payment_schedule_item)

    expected_capture_date = (payment_schedule_item.due_date + 1.day).iso8601
    transactions = [format_transaction(operation_type: "DEBIT", expected_capture_date: expected_capture_date)]

    assert @service.find_transaction_by_payment_schedule_item(transactions, payment_schedule_item)

    expected_capture_date = (payment_schedule_item.due_date + 2.days).iso8601
    transactions = [format_transaction(operation_type: "DEBIT", expected_capture_date: expected_capture_date)]

    assert_nil @service.find_transaction_by_payment_schedule_item(transactions, payment_schedule_item)

    expected_capture_date = (payment_schedule_item.due_date - 2.days).iso8601
    transactions = [format_transaction(operation_type: "DEBIT", expected_capture_date: expected_capture_date)]

    assert_nil @service.find_transaction_by_payment_schedule_item(transactions, payment_schedule_item)

    expected_capture_date = payment_schedule_item.due_date.iso8601
    transactions = [format_transaction(operation_type: "CREDIT", expected_capture_date: expected_capture_date)]

    assert_nil @service.find_transaction_by_payment_schedule_item(transactions, payment_schedule_item)
  end
end