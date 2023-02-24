# frozen_string_literal: true

require 'test_helper'

module Events; end

class Events::DeleteTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'delete an event' do
    event = Event.first
    delete "/api/events/#{event.id}?mode=single", headers: default_headers

    # Check response format & status
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type
    res = json_response(response.body)
    assert_equal 1, res[:deleted]

    # Check the event was correctly deleted
    assert_raise ActiveRecord::RecordNotFound do
      event.reload
    end
  end

  test 'soft delete an event' do
    event = Event.first

    # Make a reservation on this event
    post '/api/local_payment/confirm_payment',
         params: {
           customer_id: User.find_by(username: 'pdurand').id,
           items: [
             {
               reservation: {
                 reservable_id: event.id,
                 reservable_type: 'Event',
                 nb_reserve_places: 2,
                 slots_reservations_attributes: [
                   {
                     slot_id: event.availability.slots.first&.id,
                     offered: false
                   }
                 ]
               }
             }
           ]
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body

    assert_not event.destroyable?
    delete "/api/events/#{event.id}?mode=single", headers: default_headers
    assert_response :success
    res = json_response(response.body)
    assert_equal 1, res[:deleted]

    event.reload
    assert_not_nil event.deleted_at
  end
end
