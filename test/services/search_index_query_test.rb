# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class SearchIndexQueryTest < ActiveSupport::TestCase
  test 'calendar intervals preserve DST units while multiples of fixed units stay fixed' do
    %w[year quarter month week day hour minute second 1M 1d].each do |interval|
      result = translated_histogram(interval)
      assert_equal interval, result['calendar_interval']
      assert_not result.key?('interval')
      assert_equal 'America/Toronto', result['time_zone']
      assert_equal '-1d', result['offset']
    end
    assert_equal '24h', translated_histogram('24h')['fixed_interval']
    assert_raises(SearchIndex::UnsupportedQuery) { translated_histogram('2M') }
  end

  test 'stored queries remain unchanged and exact totals cannot be disabled' do
    query = { 'track_total_hits' => false,
              'aggs' => { 'cart' => { 'avg' => { 'field' => 'ca', 'script' => SearchIndex::Query::AVERAGE_CART_SCRIPT } } } }
    original = Marshal.load(Marshal.dump(query))
    result = SearchIndex::Query.build(query)
    assert_equal original, query
    assert_equal true, result['track_total_hits']
    assert_equal 'painless', result.dig('aggs', 'cart', 'avg', 'script', 'lang')
    assert_raises(SearchIndex::UnsupportedQuery) { SearchIndex::Query.build(pit: { id: 'foreign' }) }
  end

  test 'approximate totals and missing bulk items never become a successful export' do
    assert_raises(SearchIndex::IncompleteRead) do
      SearchIndex::Result.new('hits' => { 'hits' => [], 'total' => { 'value' => 10_000, 'relation' => 'gte' } })
    end
    response = { 'items' => [], 'errors' => false }
    SearchIndex.stub(:request, response) do
      assert_raises(SearchIndex::BulkFailure) { SearchIndex.bulk_index(family: 'account', documents: [{ id: 'a', source: {} }]) }
    end
  end

  private

  def translated_histogram(interval)
    query = { aggs: { days: { date_histogram: { field: 'date', interval: interval, time_zone: 'America/Toronto', offset: '-1d' } } } }
    SearchIndex::Query.build(query).dig('aggs', 'days', 'date_histogram')
  end
end
