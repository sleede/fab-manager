class EventsTest < ActionDispatch::IntegrationTest

  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'creation modification reservation and re-modification scenario' do

    # First, we create a new event
    post '/api/events',
         {
             event: {
                 title: 'OpenLab discovery day',
                 description: 'A day to discover the Fablab and try its machines and possibilities.',
                 start_date: 1.week.from_now.utc,
                 start_time: 1.week.from_now.utc.change({hour: 16}),
                 end_date: 1.week.from_now.utc,
                 end_time: 1.week.from_now.utc.change({hour: 20}),
                 category_id: Category.first.id,
                 amount: 0
             }
         }.to_json,
         default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the event was created correctly
    event = json_response(response.body)
    e = Event.where(id: event[:id]).first
    assert_not_nil e, 'Event was not created in database'

    # Check the remaining free places are not defined
    assert_nil e.nb_free_places, "Free places shouldn't be defined"

    # Then, modify the event to set a nb of places
    put "/api/events/#{e.id}",
        {
            event: {
                title: 'OpenLab discovery day',
                description: 'A day to discover the Fablab and try its machines and possibilities.',
                start_date: 1.week.from_now.utc,
                start_time: 1.week.from_now.utc.change({hour: 16}),
                end_date: 1.week.from_now.utc,
                end_time: 1.week.from_now.utc.change({hour: 20}),
                category_id: Category.first.id,
                amount: 0,
                nb_total_places: 10
            }
        }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the places numbers were updated successfully
    e = Event.where(id: event[:id]).first
    assert_equal 10, e.nb_total_places, 'Total number of places was not updated'
    assert_equal 10, e.nb_free_places, 'Number of free places was not updated'

    # Now, let's make a reservation on this event
    post '/api/reservations',
        {
            reservation: {
                user_id: User.find_by_username('pdurand').id,
                reservable_id: e.id,
                reservable_type: 'Event',
                nb_reserve_places: 2,
                nb_reserve_reduced_places: 0,
                slots_attributes: [
                    {
                        start_at: e.availability.start_at,
                        end_at: e.availability.end_at,
                        availability_id: e.availability.id,
                        offered: false
                    }
                ]
            }
        }.to_json,
        default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the remaining places were updated successfully
    e = Event.where(id: event[:id]).first
    assert_equal 8, e.nb_free_places, 'Number of free places was not updated'

    # Finally, modify the event to add some places
    put "/api/events/#{e.id}",
        {
            event: {
                title: 'OpenLab discovery day',
                description: 'A day to discover the Fablab and try its machines and possibilities.',
                start_date: 1.week.from_now.utc,
                start_time: 1.week.from_now.utc.change({hour: 16}),
                end_date: 1.week.from_now.utc,
                end_time: 1.week.from_now.utc.change({hour: 20}),
                category_id: Category.first.id,
                amount: 0,
                nb_total_places: 20
            }
        }

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_equal Mime::JSON, response.content_type

    # Check the places numbers were updated successfully
    e = Event.where(id: event[:id]).first
    assert_equal 20, e.nb_total_places, 'Total number of places was not updated'
    assert_equal 18, e.nb_free_places, 'Number of free places was not updated'
  end
end
