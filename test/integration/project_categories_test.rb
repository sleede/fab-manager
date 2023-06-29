# frozen_string_literal: true

require 'test_helper'

class ProjectCategoriesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a project_category' do
    post '/api/project_categories',
         params: {
           name: 'Module de fou'
         }.to_json,
         headers: default_headers

    # Check response format & project_category
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct project_category was created
    res = json_response(response.body)
    project_category = ProjectCategory.where(id: res[:id]).first
    assert_not_nil project_category, 'project_category was not created in database'

    assert_equal 'Module de fou', res[:name]
  end

  test 'update a project_category' do
    patch '/api/project_categories/1',
          params: {
            name: 'Nouveau nom'
          }.to_json,
          headers: default_headers

    # Check response format & project_category
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the project_category was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Nouveau nom', res[:name]
  end

  test 'list all project_categories' do
    get '/api/project_categories'

    # Check response format & project_category
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    project_categories = json_response(response.body)
    assert_equal ProjectCategory.count, project_categories.count
  end

  test 'delete a project_category' do
    project_category = ProjectCategory.create!(name: 'Gone too soon')
    delete "/api/project_categories/#{project_category.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      project_category.reload
    end
  end
end
