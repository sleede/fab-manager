# frozen_string_literal: true

require 'test_helper'

class ReservationContextsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a reservation_context' do
    applicable_on = ["machine", "space", "training"]
    post '/api/reservation_contexts',
         params: {
           name: 'Enseignant',
           applicable_on: applicable_on
         }.to_json,
         headers: default_headers

    # Check response format & reservation_context
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct reservation_context was created
    res = json_response(response.body)
    reservation_context = ReservationContext.where(id: res[:id]).first
    assert_not_nil reservation_context, 'reservation_context was not created in database'

    assert_equal 'Enseignant', res[:name]
    assert_equal applicable_on, res[:applicable_on]
  end

  test 'update a reservation_context' do
    applicable_on = ["machine"]
    patch '/api/reservation_contexts/1',
          params: {
            name: 'Nouveau nom',
            applicable_on: applicable_on
          }.to_json,
          headers: default_headers

    # Check response format & reservation_context
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the reservation_context was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Nouveau nom', res[:name]
    assert_equal applicable_on, res[:applicable_on]
  end

  test 'list all reservation_contexts' do
    logout @admin
    get '/api/reservation_contexts'

    # Check response format & reservation_context
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    reservation_contexts = json_response(response.body)
    assert_equal ReservationContext.count, reservation_contexts.count
    assert_equal reservation_contexts(:reservation_context_1).name, reservation_contexts[0][:name]
  end

  test "list all applicable_on possible values" do
    get '/api/reservation_contexts/applicable_on_values'

    # Check response format & reservation_context
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    applicable_on_values = json_response(response.body)
    assert_equal %w[machine space training], applicable_on_values
  end

  test 'delete a reservation_context' do
    reservation_context = ReservationContext.create!(name: 'Gone too soon')
    delete "/api/reservation_contexts/#{reservation_context.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      reservation_context.reload
    end
  end
end
