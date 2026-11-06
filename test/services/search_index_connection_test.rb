# frozen_string_literal: true

require 'test_helper'
require 'open3'

# Elasticsearch is verified on first use, never during Rails boot (assets, migrations, rake).
class SearchIndexConnectionTest < ActiveSupport::TestCase
  KEYS = %w[ELASTICSEARCH_URL ELASTICSEARCH_PASSWORD ELASTICSEARCH_PASSWORD_FILE].freeze

  setup do
    @previous = KEYS.index_with { |key| ENV.fetch(key, nil) }
    SearchIndex::Connection.reset!
  end

  teardown do
    @previous.each { |key, value| ENV[key] = value }
    SearchIndex::Connection.reset!
  end

  test 'unavailable configuration fails the search operation and health, then recovers' do
    ENV['ELASTICSEARCH_PASSWORD'] = nil
    ENV['ELASTICSEARCH_PASSWORD_FILE'] = '/nonexistent/runtime_password'
    assert_raises(SearchIndex::Connection::Unavailable) { SearchIndex::Connection.client }
    assert_not SearchIndex.healthy?
    ENV['ELASTICSEARCH_URL'] = 'http://elasticsearch:9200'
    ENV['ELASTICSEARCH_PASSWORD_FILE'] = @previous['ELASTICSEARCH_PASSWORD_FILE']
    ENV['ELASTICSEARCH_PASSWORD'] = @previous['ELASTICSEARCH_PASSWORD']
    assert_raises(SearchIndex::Connection::Unavailable) { SearchIndex::Connection.client }
  end

  test 'Rails boots and runs tasks without reaching Elasticsearch or reading its secrets' do
    environment = { 'ELASTICSEARCH_URL' => 'https://unreachable.invalid:9200', 'ELASTICSEARCH_PASSWORD' => nil,
                    'ELASTICSEARCH_PASSWORD_FILE' => '/nonexistent/runtime_password', 'ELASTICSEARCH_CA_FILE' => '/nonexistent/ca.crt' }
    output, status = Open3.capture2e(environment, 'bin/rails', 'runner', 'puts ["booted", SearchIndex::Connection.name].join(":")',
                                     chdir: Rails.root.to_s)
    assert status.success?, output
    assert_includes output, 'booted:SearchIndex::Connection'
  end
end
