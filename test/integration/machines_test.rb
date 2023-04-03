# frozen_string_literal: true

require 'test_helper'

class MachinesTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a machine' do
    name = 'IJFX 350 Laser'
    post '/api/machines',
         params: {
           machine: {
             name: name,
             machine_image_attributes: {
               attachment: fixture_file_upload('machines/Laser_cutting_machine.jpg')
             },
             description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore...',
             spec: 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium...',
             machine_files_attributes: [
               { attachment: fixture_file_upload('document.pdf', 'application/pdf', true) },
               { attachment: fixture_file_upload('document2.pdf', 'application/pdf', true) }
             ],
             disabled: false,
             machine_category_id: 1
           }
         },
         headers: upload_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the machine was correctly created
    db_machine = Machine.where(name: name).first
    assert_not_nil db_machine
    assert_not_nil db_machine.machine_image.attachment
    assert_not_nil db_machine.machine_files[0].attachment
    assert_not_nil db_machine.machine_files[1].attachment
    assert_equal name, db_machine.name
    assert_not_empty db_machine.spec
    assert_not_empty db_machine.description
    assert_not db_machine.disabled
    assert_nil db_machine.deleted_at
    assert_equal db_machine.machine_category_id, 1
  end

  test 'update a machine' do
    description = '<p>lorem ipsum <strong>dolor</strong> sit amet</p>'
    put '/api/machines/3',
        params: {
          machine: {
            description: description
          }
        }.to_json,
        headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the machine was correctly updated
    db_machine = Machine.find(3)
    assert_equal description, db_machine.description
    machine = json_response(response.body)
    assert_equal description, machine[:description]
  end

  test 'delete a machine' do
    machine = Machine.find(3)
    delete "/api/machines/#{machine.id}", headers: default_headers
    assert_response :success
    assert_empty response.body
    assert_raise ActiveRecord::RecordNotFound do
      machine.reload
    end
  end

  test 'soft delete a machine' do
    machine = Machine.find(2)
    assert_not machine.destroyable?
    delete "/api/machines/#{machine.id}", headers: default_headers
    assert_response :success
    assert_empty response.body

    machine.reload
    assert_not_nil machine.deleted_at
  end
end
