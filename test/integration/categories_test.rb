# frozen_string_literal: true

require 'test_helper'

class CategoriesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a category' do
    post '/api/categories',
         params: {
           name: 'Workshop'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct category was created
    res = json_response(response.body)
    cat = Category.where(id: res[:id]).first
    assert_not_nil cat, 'category was not created in database'

    assert_equal 'Workshop', res[:name]
  end

  test 'update a category' do
    patch '/api/categories/1',
          params: {
            name: 'Stage pratique'
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the category was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Stage pratique', res[:name]
  end

  test 'list all categories' do
    get '/api/categories'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    cats = json_response(response.body)
    assert_equal Category.count, cats.count
  end

  test 'delete a category' do
    cat = Category.create!(name: 'delete me')
    delete "/api/categories/#{cat.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      cat.reload
    end
  end
end
