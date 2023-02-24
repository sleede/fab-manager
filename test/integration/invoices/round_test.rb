# frozen_string_literal: true

require 'test_helper'

module Invoices; end

class Invoices::RoundTest < ActionDispatch::IntegrationTest
  def setup
    @vlonchamp = User.find_by(username: 'vlonchamp')
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'invoice using percent coupon rounded up' do
    machine = Machine.first
    availability = machine.availabilities.first
    plan = Plan.find(5)

    # enable the VAT
    Setting.set('invoice_VAT-active', true)
    Setting.set('invoice_VAT-rate', 20)

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @vlonchamp.id,
      coupon_code: 'REDUC20',
      items: [
        {
          reservation: {
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: availability.slots.first.id
              }
            ]
          }
        },
        {
          subscription: {
            plan_id: plan.id
          }
        }
      ]
    }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # in the invoice, we should have:
    # - machine reservation = 121    (97, coupon applied)
    # - subscription = 1498          (1198, coupon applied)
    ### intermediate total = 1619
    # - coupon (20%) = -323.8 => round to 324
    ### total incl. taxes = 1295
    # - vat = 216
    # - total exct. taxes = 1079
    ### amount paid = 1295

    invoice = Invoice.last
    assert_equal 121, invoice.main_item.amount
    assert_equal 1498, invoice.other_items.last.amount
    assert_equal 1295, invoice.total

    coupon_service = CouponService.new
    total_without_coupon = coupon_service.invoice_total_no_coupon(invoice)
    assert_equal 97, coupon_service.ventilate(total_without_coupon, invoice.main_item.amount, invoice.coupon)
    assert_equal 1198, coupon_service.ventilate(total_without_coupon, invoice.other_items.last.amount, invoice.coupon)
    assert_equal 324, total_without_coupon - invoice.total

    vat_service = VatHistoryService.new
    vat_rate_groups = vat_service.invoice_vat(invoice)
    assert_equal 216, vat_rate_groups.values.pluck(:total_vat).reduce(:+)
    assert_equal 1079, invoice.invoice_items.map(&:net_amount).reduce(:+)
  end

  test 'invoice using percent coupon rounded down' do
    machine = Machine.find(3)
    availability = machine.availabilities.first
    plan = Plan.find(5)

    # enable the VAT
    Setting.set('invoice_VAT-active', true)
    Setting.set('invoice_VAT-rate', 20)

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @vlonchamp.id,
      coupon_code: 'REDUC20',
      items: [
        {
          reservation: {
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: availability.slots.first.id
              }
            ]
          }
        },
        {
          subscription: {
            plan_id: plan.id
          }
        }
      ]
    }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # in the invoice, we should have:
    # - machine reservation = 1423    (1138, coupon applied)
    # - subscription = 1498          (1198, coupon applied)
    ### intermediate total = 2921
    # - coupon (20%) = -584.2 => round to 585
    ### total incl. taxes = 2336
    # - vat = 390
    # - total exct. taxes = 1946
    ### amount paid = 2336

    invoice = Invoice.last
    assert_equal 1423, invoice.main_item.amount
    assert_equal 1498, invoice.other_items.last.amount
    assert_equal 2336, invoice.total

    coupon_service = CouponService.new
    total_without_coupon = coupon_service.invoice_total_no_coupon(invoice)
    assert_equal 1138, coupon_service.ventilate(total_without_coupon, invoice.main_item.amount, invoice.coupon)
    assert_equal 1198, coupon_service.ventilate(total_without_coupon, invoice.other_items.last.amount, invoice.coupon)
    assert_equal 585, total_without_coupon - invoice.total

    vat_service = VatHistoryService.new
    vat_rate_groups = vat_service.invoice_vat(invoice)
    assert_equal 390, vat_rate_groups.values.pluck(:total_vat).reduce(:+)
    assert_equal 1946, invoice.invoice_items.map(&:net_amount).reduce(:+)
  end

  test 'invoice using amount coupon rounded up' do
    machine = Machine.first
    availability = machine.availabilities.first
    plan = Plan.find(5)

    # enable the VAT
    Setting.set('invoice_VAT-active', true)
    Setting.set('invoice_VAT-rate', 19.6)

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @vlonchamp.id,
      coupon_code: 'GIME3EUR',
      items: [
        {
          reservation: {
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: availability.slots.first.id
              }
            ]
          }
        },
        {
          subscription: {
            plan_id: plan.id
          }
        }
      ]
    }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # in the invoice, we should have:
    # - machine reservation = 121    (99, coupon applied)
    # - subscription = 1498          (1220, coupon applied)
    ### intermediate total = 1619
    # - coupon (20%) = -300
    ### total incl. taxes = 1319
    # - vat = 216
    # - total exct. taxes = 1103
    ### amount paid = 1319

    invoice = Invoice.last
    assert_equal 121, invoice.main_item.amount
    assert_equal 1498, invoice.other_items.last.amount
    assert_equal 1319, invoice.total

    coupon_service = CouponService.new
    total_without_coupon = coupon_service.invoice_total_no_coupon(invoice)
    assert_equal 99, coupon_service.ventilate(total_without_coupon, invoice.main_item.amount, invoice.coupon)
    assert_equal 1220, coupon_service.ventilate(total_without_coupon, invoice.other_items.last.amount, invoice.coupon)
    assert_equal 300, total_without_coupon - invoice.total

    vat_service = VatHistoryService.new
    vat_rate_groups = vat_service.invoice_vat(invoice)
    assert_equal 216, vat_rate_groups.values.pluck(:total_vat).reduce(:+)
    assert_equal 1103, invoice.invoice_items.map(&:net_amount).reduce(:+)
  end

  test 'invoice using amount coupon rounded down' do
    machine = Machine.find(3)
    availability = machine.availabilities.first
    plan = Plan.find(5)

    # enable the VAT
    Setting.set('invoice_VAT-active', true)
    Setting.set('invoice_VAT-rate', 20)

    post '/api/local_payment/confirm_payment', params: {
      customer_id: @vlonchamp.id,
      coupon_code: 'GIME3EUR',
      items: [
        {
          reservation: {
            reservable_id: machine.id,
            reservable_type: machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: availability.slots.first.id
              }
            ]
          }
        },
        {
          subscription: {
            plan_id: plan.id
          }
        }
      ]
    }.to_json, headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # in the invoice, we should have:
    # - machine reservation = 1423    (1277, coupon applied)
    # - subscription = 1498          (1344, coupon applied)
    ### intermediate total = 2921
    # - coupon (20%) = -300
    ### total incl. taxes = 2621
    # - vat = 430
    # - total exct. taxes = 2191
    ### amount paid = 2621

    invoice = Invoice.last
    assert_equal 1423, invoice.main_item.amount
    assert_equal 1498, invoice.other_items.last.amount
    assert_equal 2621, invoice.total

    coupon_service = CouponService.new
    total_without_coupon = coupon_service.invoice_total_no_coupon(invoice)
    assert_equal 1277, coupon_service.ventilate(total_without_coupon, invoice.main_item.amount, invoice.coupon)
    assert_equal 1344, coupon_service.ventilate(total_without_coupon, invoice.other_items.last.amount, invoice.coupon)
    assert_equal 300, total_without_coupon - invoice.total

    vat_service = VatHistoryService.new
    vat_rate_groups = vat_service.invoice_vat(invoice)
    assert_equal 437, vat_rate_groups.values.pluck(:total_vat).reduce(:+)
    assert_equal 2184, invoice.invoice_items.map(&:net_amount).reduce(:+)
  end
end
