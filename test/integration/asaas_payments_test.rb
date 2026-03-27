# frozen_string_literal: true

require 'test_helper'

class AsaasPaymentsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.with_role(:admin).first
    @customer = User.members.without_subscription.first
    @machine = Machine.find(6)
    @slot = @machine.availabilities.first.slots.first

    login_as(@admin, scope: :user)

    Setting.set('payment_gateway', 'asaas')
    Setting.set('online_payment_module', true)
    Setting.set('asaas_environment', 'sandbox')
    Setting.set('asaas_api_key', 'asaas_test_key')
  end

  test 'create payment returns qr code payload' do
    stub_asaas_customer_create
    stub_asaas_payment_create
    stub_asaas_qr_code

    post '/api/asaas/create_payment',
         params: { cart_items: cart_payload, cpf: '06667105978' }.to_json,
         headers: default_headers

    assert_response :success
    body = json_response(response.body)
    payment = AsaasPayment.find_by!(token: body[:token])

    assert_equal 'waiting_payment', payment.status
    assert_equal 'pix-code', payment.pix_payload
    assert_equal 'encoded-image', payment.pix_encoded_image
    assert_equal 'waiting_payment', body[:status]
    assert_equal 'pix-code', body[:pix_payload]
  end

  test 'status finalizes payment created from persisted cart payload' do
    stub_asaas_customer_create
    stub_asaas_payment_create
    stub_asaas_qr_code

    post '/api/asaas/create_payment',
         params: { cart_items: cart_payload, cpf: '06667105978' }.to_json,
         headers: default_headers

    token = json_response(response.body)[:token]
    payment = AsaasPayment.find_by!(token: token)

    assert_instance_of Hash, payment.cart_items
    assert payment.cart_items.keys.all?(String)

    reservations_count = Reservation.count
    invoices_count = Invoice.count

    stub_request(:get, "https://api-sandbox.asaas.com/v3/payments/#{payment.asaas_payment_id}")
      .to_return(status: 200, body: {
        id: payment.asaas_payment_id,
        status: 'RECEIVED',
        value: 5.0
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    get "/api/asaas/payments/#{token}/status", headers: default_headers

    assert_response :success
    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoices_count + 1, Invoice.count

    payment.reload
    assert payment.paid?
    assert_instance_of Invoice, payment.result
  end

  private

  def cart_payload
    {
      customer_id: @customer.id,
      payment_method: 'transfer',
      payment_schedule: false,
      items: [
        {
          reservation: {
            reservable_id: @machine.id,
            reservable_type: @machine.class.name,
            slots_reservations_attributes: [
              {
                slot_id: @slot.id,
                offered: false
              }
            ]
          }
        }
      ]
    }
  end

  def stub_asaas_customer_create
    stub_request(:post, 'https://api-sandbox.asaas.com/v3/customers')
      .to_return(status: 200, body: { id: 'cus_test_123' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_asaas_payment_create
    stub_request(:post, 'https://api-sandbox.asaas.com/v3/payments')
      .to_return(status: 200, body: { id: 'pay_test_123' }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_asaas_qr_code
    stub_request(:get, 'https://api-sandbox.asaas.com/v3/payments/pay_test_123/pixQrCode')
      .to_return(status: 200, body: {
        payload: 'pix-code',
        encodedImage: 'encoded-image',
        expirationDate: Time.zone.parse('2026-03-28 12:00:00').iso8601
      }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end
