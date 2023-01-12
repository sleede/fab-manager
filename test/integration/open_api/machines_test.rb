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
    machines = json_response(response.body)
    assert_not_empty machines[:machines]
  end

  test 'create a machine' do
    post '/open_api/v1/machines',
         params: {
           machine: {
             name: 'IJFX 350 Laser',
             description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et...',
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

  test 'soft delete a machine' do
    assert_not Machine.find(2).destroyable?
    delete '/open_api/v1/machines/2', headers: open_api_headers(@token)
    assert_response :success
    get '/open_api/v1/machines/2', headers: open_api_headers(@token)
    assert_response :not_found
    get '/open_api/v1/machines', headers: open_api_headers(@token)
    machines = json_response(response.body)
    assert_not(machines[:machines].any? { |m| m[:id] == 2 })
  end
end
