# frozen_string_literal: true

require 'test_helper'

module OpenApi; end

class OpenApi::AvailabilitiesTest < ActionDispatch::IntegrationTest
  def setup
    @token = OpenAPI::Client.find_by(name: 'minitest').token
  end

  test 'list availabilities' do
    get '/open_api/v1/availabilities', headers: open_api_headers(@token)
    assert_response :success
    availabilities = json_response(response.body)
    assert_not_empty availabilities[:availabilities]

    assert(availabilities[:availabilities].none? { |a| a[:id].blank? })
    assert(availabilities[:availabilities].none? { |a| a[:start_at].blank? })
    assert(availabilities[:availabilities].none? { |a| a[:end_at].blank? })
    assert(availabilities[:availabilities].none? { |a| a[:available_type].blank? })
    assert(availabilities[:availabilities].none? { |a| a[:available_ids].empty? })
    assert(availabilities[:availabilities].none? { |a| a[:created_at].blank? })
    assert(availabilities[:availabilities].none? { |a| a[:slots].empty? })
    assert(availabilities[:availabilities].pluck(:slots).flatten.none? { |s| s[:id].blank? })
    assert(availabilities[:availabilities].pluck(:slots).flatten.none? { |s| s[:start_at].blank? })
    assert(availabilities[:availabilities].pluck(:slots).flatten.none? { |s| s[:end_at].blank? })
  end

  test 'list availabilities with pagination details' do
    get '/open_api/v1/availabilities?page=1&per_page=5', headers: open_api_headers(@token)
    assert_response :success
    availabilities = json_response(response.body)

    assert_equal 5, availabilities[:availabilities].count
  end

  test 'list availabilities for given IDs' do
    get '/open_api/v1/availabilities?id=[3,4]', headers: open_api_headers(@token)
    assert_response :success
    availabilities = json_response(response.body)
    assert_not_empty availabilities[:availabilities]

    assert(availabilities[:availabilities].all? { |a| [3, 4].include?(a[:id]) })
  end

  test 'list availabilities for given type' do
    get '/open_api/v1/availabilities?available_type=Machine', headers: open_api_headers(@token)
    assert_response :success
    availabilities = json_response(response.body)
    assert_not_empty availabilities[:availabilities]

    assert(availabilities[:availabilities].all? { |a| a[:available_type] == 'Machine' })
  end

  test 'list availabilities for given type and IDs' do
    get '/open_api/v1/availabilities?available_type=Machine&available_id[]=1&available_id[]=2', headers: open_api_headers(@token)
    assert_response :success
    availabilities = json_response(response.body)
    assert_not_empty availabilities[:availabilities]

    assert(availabilities[:availabilities].all? { |a| a[:available_type] == 'Machine' })
    assert(availabilities[:availabilities].all? { |a| a[:available_ids].any? { |id| [1, 2].include?(id) } })
  end

  test 'list availabilities with given available_id but no available_type does not filter by id' do
    get '/open_api/v1/availabilities?&available_id=1', headers: open_api_headers(@token)
    assert_response :success
    availabilities = json_response(response.body)
    assert_not_empty availabilities[:availabilities]

    assert(availabilities[:availabilities].any? { |a| a[:available_ids] != 1 })
  end

  test 'list availabilities with date filtering' do
    get '/open_api/v1/availabilities?after=2016-04-01T00:00:00+01:00&before=2016-05-31T23:59:59+02:00', headers: open_api_headers(@token)
    assert_response :success
    availabilities = json_response(response.body)
    assert_not_empty availabilities[:availabilities]

    assert(availabilities[:availabilities].all? do |a|
      start = Time.zone.parse(a[:start_at])
      ending = Time.zone.parse(a[:end_at])
      start >= '2016-04-01'.to_date && ending <= '2016-05-31'.to_date
    end)
  end
end
