# frozen_string_literal: true

require 'test_helper'

class CreatePlanTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.with_role(:admin).first
    login_as(admin, scope: :user)
  end

  test 'create a transversal partner plan' do
    plans_count = Plan.count

    post '/api/plans',
         params: {
           plan: {
             base_name: 'Abonnement test',
             type: 'PartnerPlan',
             group_id: 'all',
             plan_category_id: nil,
             interval: 'week',
             interval_count: 2,
             amount: 10,
             ui_weight: 0,
             is_rolling: true,
             monthly_payment: true,
             description: 'lorem ipsum dolor sit amet',
             partner_id: 6,
             plan_file_attributes: {
               attachment: fixture_file_upload('document.pdf')
             }
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the created plans
    res = json_response(response.body)
    assert_equal 2, res[:plan_ids].count
    assert_equal plans_count + 2, Plan.count

    plans = Plan.where(name: 'Abonnement test')
    assert(plans.all? { |plan| !plan.plan_file.attachment.nil? })
    assert(plans.all? { |plan| plan.type == 'PartnerPlan' })
    assert(plans.all? { |plan| plan.partner_id == 6 })
    assert(plans.all?(&:is_rolling))
  end

  test 'create a simple plan' do
    plans_count = Plan.count

    post '/api/plans',
         params: {
           plan: {
             base_name: 'Abonnement simple',
             type: 'Plan',
             group_id: 1,
             plan_category_id: nil,
             interval: 'month',
             interval_count: 1,
             amount: 40
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the created plan
    res = json_response(response.body)
    assert_equal plans_count + 1, Plan.count

    plan = Plan.find(res[:plan_ids][0])
    assert_not_nil plan
    assert_equal 'Abonnement simple', plan.base_name
    assert_not plan.is_rolling
    assert_equal 1, plan.group_id
    assert_equal 'month', plan.interval
    assert_equal 1, plan.interval_count
    assert_equal 4000, plan.amount
  end
end
