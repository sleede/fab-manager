# frozen_string_literal: true

require 'test_helper'

class CreatePlanTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'create a plan' do
    plans_count = Plan.count

    post '/api/plans',
         params: {
           plan: {
             base_name: 'Abonnement test',
             type: 'Plan',
             group_id: 1,
             plan_category_id: nil,
             interval: 'week',
             interval_count: 2,
             amount: 10,
             ui_weight: 0,
             is_rolling: true,
             monthly_payment: false,
             description: 'lorem ipsum dolor sit amet',
             partner_id: '',
             plan_file_attributes: {
               id: nil,
               _destroy: nil,
               attachment: nil
             }
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_equal Mime[:json], response.content_type

    # Check the created plan
    plan = json_response(response.body)
    assert_equal Plan.last.id, plan[:id]
    assert_equal plans_count + 1, Plan.count
  end
end
