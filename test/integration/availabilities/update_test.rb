# frozen_string_literal: true

require 'test_helper'

# module definition
module Availabilities; end

class Availabilities::UpdateTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'update an availability to remove an associated machine' do
    availability = Availability.find(4)
    machine = Machine.find(2)
    patch "/api/availabilities/#{availability.id}",
          params: {
            availability: {
              machines_attributes: [
                { id: machine.id, _destroy: true }
              ]
            }
          }

    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    res = json_response(response.body)
    assert_not_includes res[:machine_ids], machine.id

    availability.reload

    assert_empty availability.machines_availabilities.where(machine: machine)
  end
end
