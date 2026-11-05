# frozen_string_literal: true

require 'test_helper'

# The modern ES transport must coexist with the existing OAuth and OpenLab stacks.
class ElasticsearchHttpConsumersTest < ActiveSupport::TestCase
  test 'OAuth client credentials still use the locked Faraday stack' do
    request = WebMock.stub_request(:post, 'https://oauth.example.test/oauth/token')
                     .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                                body: { access_token: 'synthetic-token', token_type: 'bearer' }.to_json)
    client = OAuth2::Client.new('synthetic-id', 'synthetic-secret', site: 'https://oauth.example.test')
    assert_equal 'synthetic-token', client.client_credentials.get_token.token
    WebMock.assert_requested request
  end

  test 'OpenLab project search retains its HTTParty request contract' do
    previous_uri = Openlab.config.base_uri
    previous_options = Openlab::Client.default_options.deep_dup
    Openlab.config.base_uri = 'https://openlab.example.test'
    endpoint = "https://openlab.example.test#{Openlab.config.api_version_path}/projects"
    request = WebMock.stub_request(:get, endpoint).with(query: { q: 'laser', page: '1' })
                     .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: '[{"id":1}]')
    client = Openlab::Client.new(app_secret: 'synthetic-openlab-secret')
    assert_equal [{ 'id' => 1 }], client.projects.search('laser', page: 1).parsed_response
    WebMock.assert_requested request
  ensure
    Openlab.config.base_uri = previous_uri
    Openlab::Client.default_options.replace(previous_options)
  end
end
