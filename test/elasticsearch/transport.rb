# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

# Uses the real TLS/authenticated ES9 service from the isolated bench.
class ElasticsearchTransportTest < ActiveSupport::TestCase
  setup do
    raise 'Set ES_CONTRACT_ISOLATED=1 for disposable ES9 services' unless ENV['ES_CONTRACT_ISOLATED'] == '1'
  end

  test 'official client verifies the product and keeps all locked HTTP consumers compatible' do
    client = SearchIndex::Connection.client
    response = client.info
    assert_match(/^9\./, response.dig('version', 'number'))
    assert_equal 'Elasticsearch', response.headers['x-elastic-product']
    assert_equal '0.17.3', Gem.loaded_specs.fetch('faraday').version.to_s
    assert_equal '1.4.4', Gem.loaded_specs.fetch('oauth2').version.to_s
    assert_equal '0.0.8', Gem.loaded_specs.fetch('openlab_ruby').version.to_s
    %w[elasticsearch-model elasticsearch-persistence elasticsearch-rails elasticsearch-transport].each do |name|
      assert_not Gem.loaded_specs.key?(name)
    end
  end

  test 'invalid credentials are refused by the real server and health reports failure' do
    bad = Elasticsearch::Client.new(**connection_options.merge(password: 'invalid-disposable-password'))
    assert_raises(Elastic::Transport::Transport::Errors::Unauthorized) { bad.info }
    SearchIndex.stub(:client, bad) { assert_not SearchIndex.healthy? }
  end

  test 'untrusted TLS certificate is refused without a verification bypass' do
    bad = Elasticsearch::Client.new(**connection_options.merge(transport_options: { ssl: { verify: true } }))
    error = assert_raises(Elastic::Transport::Transport::Error) { bad.info }
    assert_match(/certificate verify failed/, error.message)
    SearchIndex.stub(:client, bad) { assert_not SearchIndex.healthy? }
  end

  test 'trusted certificates still require a matching hostname' do
    address = Addrinfo.getaddrinfo('elasticsearch', 9200, :INET).first.ip_address
    bad = Elasticsearch::Client.new(**connection_options.merge(url: "https://#{address}:9200"))
    error = assert_raises(Elastic::Transport::Transport::Error) { bad.info }
    assert_match(/certificate|hostname/i, error.message)
  end

  private

  def connection_options
    { url: ENV.fetch('ELASTICSEARCH_URL'), user: ENV.fetch('ELASTICSEARCH_USERNAME'), password: ENV.fetch('ELASTICSEARCH_PASSWORD'),
      transport_options: { ssl: { verify: true, ca_file: ENV.fetch('ELASTICSEARCH_CA_FILE') } } }
  end
end
