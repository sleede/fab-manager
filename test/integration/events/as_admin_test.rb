# frozen_string_literal: true

require 'test_helper'

module Events; end

class Events::AsAdminTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'creation modification reservation and re-modification scenario' do
    # First, we create a new event
    post '/api/events',
         params: {
           event: {
             title: 'OpenLab discovery day',
             description: 'A day to discover the Fablab and try its machines and possibilities.',
             start_date: 1.week.from_now.utc,
             start_time: 1.week.from_now.utc.change(hour: 16),
             end_date: 1.week.from_now.utc,
             end_time: 1.week.from_now.utc.change(hour: 20),
             category_id: Category.first.id,
             amount: 0
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the event was created correctly
    event = json_response(response.body)
    e = Event.where(id: event[:id]).first
    assert_not_nil e, 'Event was not created in database'

    # Check the remaining free places are not defined
    assert_nil e&.nb_free_places, "Free places shouldn't be defined"

    # Then, modify the event to set a nb of places
    put "/api/events/#{e&.id}",
        params: {
          event: {
            title: 'OpenLab discovery day',
            description: 'A day to discover the Fablab and try its machines and possibilities.',
            start_date: 1.week.from_now.utc,
            start_time: 1.week.from_now.utc.change(hour: 16),
            end_date: 1.week.from_now.utc,
            end_time: 1.week.from_now.utc.change(hour: 20),
            category_id: Category.first.id,
            amount: 0,
            nb_total_places: 10
          }
        }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the places numbers were updated successfully
    e = Event.where(id: event[:id]).first
    assert_equal 10, e&.nb_total_places, 'Total number of places was not updated'
    assert_equal 10, e&.nb_free_places, 'Number of free places was not updated'

    # Now, let's make a reservation on this event
    post '/api/local_payment/confirm_payment',
         params: {
           customer_id: User.find_by(username: 'pdurand').id,
           items: [
             {
               reservation: {
                 reservable_id: e&.id,
                 reservable_type: 'Event',
                 nb_reserve_places: 2,
                 slots_reservations_attributes: [
                   {
                     slot_id: e&.availability&.slots&.first&.id,
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
    assert_match Mime[:json].to_s, response.content_type

    # Check the remaining places were updated successfully
    e = Event.where(id: event[:id]).first
    assert_equal 8, e&.nb_free_places, 'Number of free places was not updated'

    # Finally, modify the event to add some places
    put "/api/events/#{e&.id}",
        params: {
          event: {
            title: 'OpenLab discovery day',
            description: 'A day to discover the Fablab and try its machines and possibilities.',
            start_date: 1.week.from_now.utc,
            start_time: 1.week.from_now.utc.change(hour: 16),
            end_date: 1.week.from_now.utc,
            end_time: 1.week.from_now.utc.change(hour: 20),
            category_id: Category.first.id,
            amount: 0,
            nb_total_places: 20
          }
        }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the places numbers were updated successfully
    e = Event.where(id: event[:id]).first
    assert_equal 20, e&.nb_total_places, 'Total number of places was not updated'
    assert_equal 18, e&.nb_free_places, 'Number of free places was not updated'
  end

  test 'create event with custom price and reserve it with success' do
    price_category = PriceCategory.first

    # First, we create a new event
    post '/api/events',
         params: {
           event: {
             title: 'Electronics initiation',
             description: 'A workshop about electronics and the abilities to create robots.',
             start_date: 1.week.from_now.utc + 2.days,
             start_time: 1.week.from_now.utc.change(hour: 18) + 2.days,
             end_date: 1.week.from_now.utc + 2.days,
             end_time: 1.week.from_now.utc.change(hour: 22) + 2.days,
             category_id: Category.last.id,
             amount: 20,
             nb_total_places: 10,
             event_price_categories_attributes: [
               {
                 price_category_id: price_category.id.to_s,
                 amount: 16.to_s
               }
             ]
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the event was created correctly
    event = json_response(response.body)
    e = Event.where(id: event[:id]).first
    assert_not_nil e, 'Event was not created in database'

    # Check the places numbers were set successfully
    e = Event.find(event[:id])
    assert_equal 10, e.nb_total_places, 'Total number of places was not updated'
    assert_equal 10, e.nb_free_places, 'Number of free places was not updated'

    # Now, let's make a reservation on this event
    post '/api/local_payment/confirm_payment',
         params: {
           customer_id: User.find_by(username: 'lseguin').id,
           items: [
             {
               reservation: {
                 reservable_id: e.id,
                 reservable_type: 'Event',
                 nb_reserve_places: 4,
                 slots_reservations_attributes: [
                   {
                     slot_id: e.availability.slots.first.id,
                     offered: false
                   }
                 ],
                 tickets_attributes: [
                   {
                     event_price_category_id: e.event_price_categories.first.id,
                     booked: 4
                   }
                 ]
               }
             }
           ]
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the reservation match the required event
    result = json_response(response.body)
    i = Invoice.find(result[:id])

    assert_equal e.id, i.main_item.object.reservable_id
    assert_equal 'Event', i.main_item.object.reservable_type

    # Check the remaining places were updated successfully
    e = Event.where(id: event[:id]).first
    assert_equal 2, e&.nb_free_places, 'Number of free places was not updated'

    # Check the resulting invoice generation and it has right price
    assert_invoice_pdf i
    assert_equal (4 * 20) + (4 * 16), i.total / 100.0
  end
end
