# frozen_string_literal: true

require 'test_helper'

class PayzenTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.members.first
    login_as(@user, scope: :user)

    Setting.set('payment_gateway', 'payzen')
  end

  test 'create payment with payzen' do
    training = Training.first
    availability = training.availabilities.first
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
                     slots_attributes: [
                       {
                         start_at: availability.start_at.to_s(:iso8601),
                         end_at: availability.end_at.to_s(:iso8601),
                         availability_id: availability.id
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
    availability = training.availabilities.first
    plan = Plan.find_by(group_id: @user.group.id, type: 'Plan')

    reservations_count = Reservation.count
    availabilities_count = Availability.count
    invoices_count = Invoice.count
    slots_count = Slot.count


    cart_items = {
      items: [
        {
          reservation: {
            reservable_id: training.id,
            reservable_type: training.class.name,
            slots_attributes: [
              {
                start_at: availability.start_at.to_s(:iso8601),
                end_at: availability.end_at.to_s(:iso8601),
                availability_id: availability.id
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
    id = PayZen::Helper.generate_ref(cart_items, @user.id)

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
                                       expiryYear: DateTime.current.strftime('%y'),
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
    assert_equal slots_count + 1, Slot.count
    assert_equal availabilities_count, Availability.count
  end
end
