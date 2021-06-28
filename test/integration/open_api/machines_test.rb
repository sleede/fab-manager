# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::MachinesTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list all machines' do
    get '/open_api/v1/machines', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'create a machine' do
    post '/open_api/v1/machines',
         params: {
           machine: {
             name: 'IJFX 350 Laser',
             description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore...',
             spec: 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium...',
             disabled: true
           }
         }.to_json,
         headers: open_api_headers(@token)
    assert_response :success
  end

  test 'update a machine' do
    patch '/open_api/v1/machines/3',
          params: {
            machine: {
              disabled: true,
              name: '[DISABLED] Shopbot'
            }
          }.to_json,
          headers: open_api_headers(@token)
    assert_response :success
  end

  test 'get a machine' do
    get '/open_api/v1/machines/3', headers: open_api_headers(@token)
    assert_response :success
  end

  test 'delete a machine' do
    delete '/open_api/v1/machines/3', headers: open_api_headers(@token)
    assert_response :success
  end
end
