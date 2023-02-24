# frozen_string_literal: true

require 'test_helper'

class MachineCategoriesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a machine category' do
    name = 'Category 2'
    post '/api/machine_categories',
         params: {
           machine_category: {
             name: name,
             machine_ids: [1]
           }
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the machine category was correctly created
    category = MachineCategory.where(name: name).first
    machine1 = Machine.find(1)
    assert_not_nil category
    assert_equal name, category.name
    assert_equal category.machines.length, 1
    assert_equal category.id, machine1.machine_category_id
  end

  test 'update a machine category' do
    name = 'category update'
    put '/api/machine_categories/1',
        params: {
          machine_category: {
            name: name,
            machine_ids: [2, 3]
          }
        }.to_json,
        headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the machine category was correctly updated
    category = MachineCategory.find(1)
    assert_equal name, category.name
    json = json_response(response.body)
    assert_equal name, json[:name]
    assert_equal category.machines.length, 2
    assert_equal category.machine_ids.sort, [2, 3]
  end

  test 'delete a machine category' do
    delete '/api/machine_categories/1', headers: default_headers
    assert_response :success
    assert_empty response.body
  end
end
