# frozen_string_literal: true

require 'test_helper'

class PayzenTest < ActionDispatch::IntegrationTest
  include WebMock::API

  def setup
    @user = User.members.first
    login_as(@user, scope: :user)

    Setting.set('payment_gateway', 'payzen')
  end

  test 'create payment with payzen' do
    training = Training.first
    slot = training.availabilities.first.slots.first
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan')

    VCR.use_cassette('create_payzen_payment_token_success') do
      post '/api/payzen/create_payment',
           params: {
             customer_id: @user.id,
             cart_items: {
               items: [
                 {
                   reservation: {
                     reservable_id: training.id,
                     reservable_type: training.class.name,
                     slots_reservations_attributes: [
                       {
                         slot_id: slot.id
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
             }
           }.to_json, headers: default_headers
    end

    # Check the response
    assert_equal 200, response.status
    payment = json_response(response.body)
    assert_not_nil payment[:formToken]
    assert_not_nil payment[:orderId]
  end

  test 'confirm payment with payzen' do
    require 'pay_zen/helper'
    require 'pay_zen/pci/charge'

    training = Training.first
    slot = training.availabilities.first.slots.first
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan')

    reservations_count = Reservation.count
    availabilities_count = Availability.count
    invoices_count = Invoice.count
    slots_reservation_count = SlotsReservation.count

    cart_items = {
      items: [
        {
          reservation: {
            reservable_id: training.id,
            reservable_type: training.class.name,
            slots_reservations_attributes: [
              {
                slot_id: slot.id
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
    }

    cs = CartService.new(@user)
    cart = cs.from_hash(cart_items)
    amount = cart.total[:total]
    id = 'dffd53627a4901e986862674'

    VCR.use_cassette('confirm_payzen_payment_success') do
      client = PayZen::PCI::Charge.new
      result = client.create_payment(amount: amount,
                                     order_id: id,
                                     customer: PayZen::Helper.generate_customer(@user.id, @user.id, cart_items),
                                     device: {
                                       deviceType: 'BROWSER',
                                       acceptHeader: 'text/html',
                                       userAgent: 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101',
                                       ip: '69.89.31.226',
                                       javaEnabled: true,
                                       language: 'fr-FR',
                                       colorDepth: '32',
                                       screenHeight: 768,
                                       screenWidth: 1258,
                                       timeZoneOffset: -120
                                     },
                                     payment_forms: [{
                                       paymentMethodType: 'CARD',
                                       pan: '4970100000000055',
                                       expiryMonth: 12,
                                       expiryYear: Time.current.strftime('%y'),
                                       securityCode: 123
                                     }])

      assert_equal 'PAID', result['answer']['orderStatus'], 'Order is not PAID, something went wrong with PayZen'
      assert_equal id, result['answer']['orderDetails']['orderId'], 'Order ID does not match, something went wrong with PayZen'

      post '/api/payzen/confirm_payment',
           params: {
             cart_items: cart_items,
             order_id: result['answer']['orderDetails']['orderId']
           }.to_json, headers: default_headers
    end

    # Check the response
    assert_equal 201, response.status
    invoice = json_response(response.body)
    assert_equal Invoice.last.id, invoice[:id]
    assert_equal amount / 100.0, invoice[:total]

    assert_equal reservations_count + 1, Reservation.count
    assert_equal invoices_count + 1, Invoice.count
    assert_equal slots_reservation_count + 1, SlotsReservation.count
    assert_equal availabilities_count, Availability.count
  end

  test 'sdk_test is forbidden for regular members and unauthenticated users' do
    logout
    post '/api/payzen/sdk_test',
         params: { base_url: 'https://attacker.com', username: 'user', password: 'password' }.to_json,
         headers: default_headers
    assert_response :unauthorized

    login_as(@user, scope: :user)
    post '/api/payzen/sdk_test',
         params: { base_url: 'https://attacker.com', username: 'user', password: 'password' }.to_json,
         headers: default_headers
    assert_response :forbidden
  end

  test 'sdk_test as admin rejects unapproved origins and SSRF destinations' do
    admin = User.admins.first
    login_as(admin, scope: :user)

    invalid_urls = [
      'http://api.payzen.eu',
      'https://unapproved.api.payzen.eu',
      'https://attacker.com',
      'https://127.0.0.1',
      'https://[::1]',
      'https://169.254.169.254',
      'https://10.0.0.1',
      'https://192.168.1.1',
      'https://evil-payzen.eu',
      'https://api.payzen.eu.attacker.com',
      'https://api.payzen.eu:8443',
      'https://api.payzen.eu/evil/path',
      'https://api.payzen.eu?param=1'
    ]

    invalid_urls.each do |url|
      post '/api/payzen/sdk_test',
           params: { base_url: url, username: 'user', password: 'password' }.to_json,
           headers: default_headers
      assert_response :bad_request, "Expected #{url} to be rejected with 400 Bad Request"
      json = json_response(response.body)
      assert_equal 'Invalid or untrusted PayZen endpoint', json[:error]
    end
  end

  test 'sdk_test as admin rejects incomplete parameters when custom settings are provided' do
    admin = User.admins.first
    login_as(admin, scope: :user)

    incomplete_payloads = [
      { base_url: '' },
      { base_url: nil },
      { base_url: ['https://api.payzen.eu'] },
      { base_url: { host: 'api.payzen.eu' } },
      { base_url: 'https://api.payzen.eu' },
      { base_url: 'https://api.payzen.eu', username: '' },
      { base_url: 'https://api.payzen.eu', username: 'user' },
      { base_url: 'https://api.payzen.eu', password: 'pass' },
      { base_url: 'https://api.payzen.eu', username: 'user', password: '' },
      { username: 'user' },
      { password: 'pass' }
    ]

    incomplete_payloads.each do |payload|
      post '/api/payzen/sdk_test', params: payload.to_json, headers: default_headers
      assert_response :bad_request
      json = json_response(response.body)
      assert_equal 'Missing PayZen test parameters', json[:error]
    end
  end

  test 'payzen client never transmits stored credentials when custom destination is specified' do
    Setting.set('payzen_username', 'stored_prod_user')
    Setting.set('payzen_password', 'stored_prod_password')

    client = PayZen::Client.new(base_url: 'https://api.payzen.eu', username: 'custom_user', password: 'custom_password')
    auth_header = client.send(:authorization_header)
    assert_equal "Basic #{Base64.strict_encode64('custom_user:custom_password')}", auth_header

    decoded = Base64.decode64(auth_header.delete_prefix('Basic '))
    assert_equal 'custom_user:custom_password', decoded
    refute_includes decoded, 'stored_prod_user'
    refute_includes decoded, 'stored_prod_password'

    incomplete_client = PayZen::Client.new(base_url: 'https://api.payzen.eu')
    assert_raises(PayzenError) { incomplete_client.send(:authorization_header) }
  end

  test 'sdk_test as admin uses stored configuration when no custom parameters are provided' do
    admin = User.admins.first
    login_as(admin, scope: :user)

    Setting.set('payzen_endpoint', 'https://api.payzen.eu')
    Setting.set('payzen_username', 'stored_user')
    Setting.set('payzen_password', 'stored_pass')

    stub_request(:post, 'https://api.payzen.eu/api-payment/V4/Charge/SDKTest')
      .with(
        headers: { 'Authorization' => "Basic #{Base64.strict_encode64('stored_user:stored_pass')}" },
        body: { value: 'fab-manager' }.to_json
      )
      .to_return(status: 200, body: '{"answer":{"value":"fab-manager"}}', headers: { 'Content-Type' => 'application/json' })

    post '/api/payzen/sdk_test', params: {}.to_json, headers: default_headers
    assert_response :success
    json = json_response(response.body)
    assert_equal true, json[:success]
  end

  test 'sdk_test as admin handles success, redirects, and network failures safely' do
    admin = User.admins.first
    login_as(admin, scope: :user)

    # Success case
    stub_request(:post, 'https://api.payzen.eu/api-payment/V4/Charge/SDKTest')
      .with(
        headers: { 'Authorization' => "Basic #{Base64.strict_encode64('user:password')}" },
        body: { value: 'fab-manager' }.to_json
      )
      .to_return(status: 200, body: '{"answer":{"value":"fab-manager"}}', headers: { 'Content-Type' => 'application/json' })

    post '/api/payzen/sdk_test',
         params: { base_url: 'https://api.payzen.eu', username: 'user', password: 'password' }.to_json,
         headers: default_headers
    assert_response :success
    json = json_response(response.body)
    assert_equal true, json[:success]

    # Redirect (302) rejection case - must not follow redirects
    stub_request(:post, 'https://api.payzen.eu/api-payment/V4/Charge/SDKTest')
      .to_return(status: 302, headers: { 'Location' => 'http://127.0.0.1/evil' })

    post '/api/payzen/sdk_test',
         params: { base_url: 'https://api.payzen.eu', username: 'user', password: 'password' }.to_json,
         headers: default_headers
    assert_response :success
    json = json_response(response.body)
    assert_equal false, json[:success]
    assert_not_requested(:any, 'http://127.0.0.1/evil')

    # Network timeout case
    stub_request(:post, 'https://api.payzen.eu/api-payment/V4/Charge/SDKTest').to_timeout

    post '/api/payzen/sdk_test',
         params: { base_url: 'https://api.payzen.eu', username: 'user', password: 'password' }.to_json,
         headers: default_headers
    assert_response :success
    json = json_response(response.body)
    assert_equal false, json[:success]
  end
end
