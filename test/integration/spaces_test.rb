# frozen_string_literal: true

require 'test_helper'

class SpacesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a space' do
    name = 'Biolab'
    post '/api/spaces',
         params: {
           space: {
             name: name,
             space_image_attributes: {
               attachment: fixture_file_upload('spaces/Biology_laboratory.jpg')
             },
             description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras ante mi, porta ac dictum quis, feugiat...',
             characteristics: 'Sed fermentum ante ut elit lobortis, id auctor libero cursus. Sed augue lectus, mollis at luctus eu...',
             default_places: 6,
             space_files_attributes: [
               { attachment: fixture_file_upload('document.pdf', 'application/pdf', true) },
               { attachment: fixture_file_upload('document2.pdf', 'application/pdf', true) }
             ],
             disabled: false
           }
         },
         headers: upload_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the space was correctly created
    db_space = Space.where(name: name).first
    assert_not_nil db_space
    assert_not_nil db_space.space_image.attachment
    assert_not_nil db_space.space_files[0].attachment
    assert_not_nil db_space.space_files[1].attachment
    assert_equal name, db_space.name
    assert_equal 6, db_space.default_places
    assert_not_empty db_space.characteristics
    assert_not_empty db_space.description
    assert_not db_space.disabled
    assert_nil db_space.deleted_at
  end

  test 'update a space' do
    description = '<p>lorem ipsum <strong>dolor</strong> sit amet</p>'
    put '/api/spaces/1',
        params: {
          space: {
            description: description
          }
        }.to_json,
        headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the space was correctly updated
    db_space = Space.find(1)
    assert_equal description, db_space.description
    space = json_response(response.body)
    assert_equal description, space[:description]
  end

  test 'delete a space' do
    delete '/api/spaces/1', headers: default_headers
    assert_response :success
    assert_empty response.body
  end
end
