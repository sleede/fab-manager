# frozen_string_literal: true

require 'test_helper'

class CreateCartItemTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.find_by(username: 'pdurand')
    login_as(@user, scope: :user)
    @order = Cart::FindOrCreateService.new(@user).call(nil)
  end

  test 'create a subscription' do
    plan = Plan.first
    post '/api/cart/create_item',
         params: {
           order_token: @order.token,
           subscription: {
             plan_id: plan.id
           }
         }
    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the cart item was created correctly
    res = json_response(response.body)
    resource = res[:type].classify.constantize.find(res[:id])
    assert resource.is_a? CartItem::Subscription
    assert_equal plan, resource.plan
  end

  test 'create a machine reservation' do
    machine = Machine.first
    slots = Availabilities::AvailabilitiesService.new(@user)
                                                 .machines([machine], @user, { start: Time.current, end: 10.days.from_now })
    post '/api/cart/create_item',
         params: {
           order_token: @order.token,
           reservation: {
             reservable_id: machine.id,
             reservable_type: 'Machine',
             slots_reservations_attributes: [
               { slot_id: slots&.last&.id }
             ]
           }
         }
    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the cart item was created correctly
    res = json_response(response.body)
    resource = res[:type].classify.constantize.find(res[:id])
    assert resource.is_a? CartItem::MachineReservation
    assert_equal machine, resource.reservable
  end

  test 'create a space reservation' do
    space = Space.first
    post '/api/cart/create_item',
         params: {
           order_token: @order.token,
           reservation: {
             reservable_id: space.id,
             reservable_type: 'Space',
             slots_reservations_attributes: [
               { slot_id: space.availabilities.last&.slots&.last&.id }
             ]
           }
         }
    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the cart item was created correctly
    res = json_response(response.body)
    resource = res[:type].classify.constantize.find(res[:id])
    assert resource.is_a? CartItem::SpaceReservation
    assert_equal space, resource.reservable
  end

  test 'create a training reservation' do
    training = Training.first
    post '/api/cart/create_item',
         params: {
           order_token: @order.token,
           reservation: {
             reservable_id: training.id,
             reservable_type: 'Training',
             slots_reservations_attributes: [
               { slot_id: training.availabilities.last&.slots&.last&.id }
             ]
           }
         }
    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the cart item was created correctly
    res = json_response(response.body)
    resource = res[:type].classify.constantize.find(res[:id])
    assert resource.is_a? CartItem::TrainingReservation
    assert_equal training, resource.reservable
  end

  test 'create an event reservation' do
    event = Event.find(4)
    post '/api/cart/create_item',
         params: {
           order_token: @order.token,
           reservation: {
             reservable_id: event.id,
             reservable_type: 'Event',
             slots_reservations_attributes: [
               { slot_id: event.availability.slots.last&.id }
             ],
             nb_reserve_places: 2
           }
         }
    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the cart item was created correctly
    res = json_response(response.body)
    resource = res[:type].classify.constantize.find(res[:id])
    assert resource.is_a? CartItem::EventReservation
    assert_equal event, resource.event
    assert_equal 2, resource.normal_tickets
  end

  test 'create a prepaid-pack' do
    pack = PrepaidPack.first
    post '/api/cart/create_item',
         params: {
           order_token: @order.token,
           prepaid_pack: { id: pack.id }
         }
    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the cart item was created correctly
    res = json_response(response.body)
    resource = res[:type].classify.constantize.find(res[:id])
    assert resource.is_a? CartItem::PrepaidPack
    assert_equal pack.id, resource.prepaid_pack_id
  end

  test 'create a free-extension for a subscription' do
    subscription = @user.subscription
    post '/api/cart/create_item',
         params: {
           order_token: @order.token,
           free_extension: { end_at: subscription.expiration_date + 1.month }
         }
    # general assertions
    assert_equal 201, response.status
    assert_match Mime[:json].to_s, response.content_type

    # Check the cart item was created correctly
    res = json_response(response.body)
    resource = res[:type].classify.constantize.find(res[:id])
    assert resource.is_a? CartItem::FreeExtension
    assert_equal subscription.id, resource.subscription_id
  end
end
