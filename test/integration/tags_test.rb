# frozen_string_literal: true

require 'test_helper'

class TagsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a tag' do
    post '/api/tags',
         params: {
           name: 'Atelier coco'
         }.to_json,
         headers: default_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the correct tag was created
    res = json_response(response.body)
    tag = Tag.where(id: res[:id]).first
    assert_not_nil tag, 'tag was not created in database'

    assert_equal 'Atelier coco', res[:name]
  end

  test 'update a tag' do
    patch '/api/tags/1',
          params: {
            name: 'Hardcore bidouilleurs'
          }.to_json,
          headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the tag was updated
    res = json_response(response.body)
    assert_equal 1, res[:id]
    assert_equal 'Hardcore bidouilleurs', res[:name]
  end

  test 'list all tags' do
    get '/api/tags'

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the list items are ok
    tags = json_response(response.body)
    assert_equal Tag.count, tags.count
  end

  test 'delete a tag' do
    tag = Tag.create!(name: 'delete me')
    delete "/api/tags/#{tag.id}"
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      tag.reload
    end
  end
end
