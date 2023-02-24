# frozen_string_literal: true

require 'test_helper'

class TrainingsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a training' do
    name = 'First aid training'
    post '/api/trainings',
         params: {
           training: {
             name: name,
             training_image_attributes: {
               attachment: fixture_file_upload('trainings/first-aid.jpg')
             },
             description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore...',
             machine_ids: [],
             nb_total_places: 10,
             public_page: true,
             disabled: false,
             advanced_accounting_attributes: {
               code: '706200',
               analytical_section: '9A41B'
             }
           }
         },
         headers: upload_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the training was correctly created
    db_training = Training.where(name: name).first
    assert_not_nil db_training
    assert_not_nil db_training.training_image.attachment
    assert_equal name, db_training.name
    assert_equal 10, db_training.nb_total_places
    assert_empty db_training.machine_ids
    assert_not_empty db_training.description
    assert db_training.public_page
    assert_not db_training.disabled
    assert_equal '706200', db_training.advanced_accounting.code
    assert_equal '9A41B', db_training.advanced_accounting.analytical_section
  end

  test 'update a training' do
    description = '<p>lorem ipsum <strong>dolor</strong> sit amet</p>'
    put '/api/trainings/3',
        params: {
          training: {
            description: description,
            public_page: false
          }
        }.to_json,
        headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the training was correctly updated
    db_training = Training.find(3)
    assert_equal description, db_training.description
    assert_not db_training.public_page
    training = json_response(response.body)
    assert_equal description, training[:description]
    assert_not training[:public_page]
  end

  test 'user validates a training' do
    training = Training.find(3)
    user = User.find(9)
    put "/api/trainings/#{training.id}", params: { training: {
      users: [user.id]
    } }.to_json, headers: default_headers

    # Check response status
    assert_equal 204, response.status, response.body

    # Check user is authorized
    assert user.training_machine?(Machine.find(5))
  end

  test 'delete a training' do
    delete '/api/trainings/4', headers: default_headers
    assert_response :success
    assert_empty response.body
  end
end
