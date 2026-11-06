# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

# Error contracts complement the live ES9 characterization, without hiding transport failures.
class SearchIndexTest < ActiveSupport::TestCase
  test 'catalogue accepts only the ten physical families' do
    assert_equal 'availabilities', SearchIndex.family_for(index: 'fablab', type: 'availabilities')
    assert_equal({ index: 'fm-stats-order' }, SearchIndex.target('order'))
    assert_raises(ArgumentError) { SearchIndex.target('../secrets') }
    assert_raises(ArgumentError) { SearchIndex.family_for(index: 'another-index', type: 'account') }
    assert_raises(ArgumentError) { SearchIndex.build_stat(family: 'availabilities', attributes: {}) }
  end

  test 'result keeps family distinct from business type and opaque ID' do
    result = SearchIndex::Result.new(page('one', 1, ['0009007199254740993']))
    assert_equal({ 'value' => 1, 'relation' => 'eq' }, result.total)
    assert_equal({ 'family' => 'account', 'id' => '0009007199254740993', '_source' => { 'type' => 'member', 'stat' => 0 } }, result.hits.first)
    assert_equal 1, result.legacy_response.dig('hits', 'total')
    assert_equal 'account', result.legacy_response.dig('hits', 'hits', 0, '_type')
  end

  test 'cursor releases the latest scroll ID after an empty page' do
    client = Minitest::Mock.new
    client.expect(:search, page('one', 2, %w[a]), **search_options)
    client.expect(:scroll, page('two', 2, %w[b]), body: { scroll: '30s', scroll_id: 'one' })
    client.expect(:scroll, page('three', 2, []), body: { scroll: '30s', scroll_id: 'two' })
    client.expect(:clear_scroll, {}, body: { scroll_id: ['three'] })
    SearchIndex.stub(:client, client) do
      assert_equal %w[a b], (SearchIndex.each_hit(family: 'account', query: {}, page_size: 1).map { |hit| hit['id'] })
    end
    client.verify
  end

  test 'cursor rejects truncated duplicate and partial reads and always closes' do
    [page('two', 2, []), page('two', 2, %w[a]), page('two', 2, %w[b]).merge('_shards' => { 'failed' => 1 })].each do |next_page|
      client = Minitest::Mock.new
      client.expect(:search, page('one', 2, %w[a]), **search_options)
      client.expect(:scroll, next_page, body: { scroll: '30s', scroll_id: 'one' })
      client.expect(:clear_scroll, {}, body: { scroll_id: ['two'] })
      SearchIndex.stub(:client, client) do
        assert_raises(SearchIndex::IncompleteRead) { SearchIndex.each_hit(family: 'account', query: {}, page_size: 1).to_a }
      end
      client.verify
    end
  end

  test 'cursor closes an initially partial response and an interrupted consumer' do
    [true, false].each do |partial|
      client = Minitest::Mock.new
      response = page('one', 1, %w[a]).merge('timed_out' => partial)
      client.expect(:search, response, **search_options)
      client.expect(:clear_scroll, {}, body: { scroll_id: ['one'] })
      SearchIndex.stub(:client, client) do
        expected = partial ? SearchIndex::IncompleteRead : IOError
        assert_raises(expected) { SearchIndex.each_hit(family: 'account', query: {}, page_size: 1, &method(:fail_consumer)) }
      end
      client.verify
    end
  end

  test 'scoped deletion reports failures conflicts and timeouts' do
    [{ 'failures' => [{ 'reason' => 'rejected' }] }, { 'version_conflicts' => 1 }, { 'timed_out' => true }].each do |response|
      client = Minitest::Mock.new
      client.expect(:delete_by_query, response, index: 'fm-stats-machine', body: { 'query' => { 'match_all' => {} } })
      SearchIndex.stub(:client, client) do
        assert_raises(SearchIndex::IncompleteRead) { SearchIndex.delete_by_query(family: 'machine', query: { match_all: {} }) }
      end
      client.verify
    end
  end

  test 'deletion that explicitly proceeds on conflicts accepts them but still reports failures' do
    options = { index: 'fm-stats-machine', conflicts: 'proceed', body: { 'query' => { 'match_all' => {} } } }
    client = Minitest::Mock.new
    client.expect(:delete_by_query, { 'deleted' => 1, 'version_conflicts' => 2, 'failures' => [] }, **options)
    client.expect(:delete_by_query, { 'version_conflicts' => 2, 'failures' => [{ 'reason' => 'rejected' }] }, **options)
    SearchIndex.stub(:client, client) do
      assert_equal 1, SearchIndex.delete_by_query(family: 'machine', conflicts: 'proceed', query: { match_all: {} })['deleted']
      assert_raises(SearchIndex::IncompleteRead) do
        SearchIndex.delete_by_query(family: 'machine', conflicts: 'proceed', query: { match_all: {} })
      end
    end
    client.verify
  end

  test 'committed cancellation still succeeds when the statistics deletion is incomplete' do
    slot_reservation = SlotsReservation.where(canceled_at: nil).first
    failing = ->(**) { raise SearchIndex::IncompleteRead, 'Incomplete Elasticsearch deletion' }
    SearchIndex.stub(:delete_by_query, failing) do
      assert SlotsReservationsService.cancel(slot_reservation)
    end
    assert_not_nil slot_reservation.reload.canceled_at
  end

  test 'unknown physical indices require migration review' do
    response = page('one', 1, %w[a])
    response['hits']['hits'].first['_index'] = 'unknown-site-index'
    assert_raises(SearchIndex::SchemaConflict) { SearchIndex::Result.new(response) }
  end

  test 'statistics URL parameters cannot replace the route family or the request body' do
    env = Rack::MockRequest.env_for('/stats/machine/_search?family=all_stats&query=x&scroll=30s',
                                    method: 'POST', input: '{"size":0}', 'CONTENT_TYPE' => 'application/json')
    received = nil
    capture = lambda do |**arguments|
      received = arguments
      SearchIndex::Result.new(page(nil, 0, []))
    end
    SearchIndex.stub(:search, capture) do
      Statistics::QueryService.query('machine', ActionDispatch::Request.new(env))
    end
    assert_equal({ family: 'machine', query: { 'size' => 0 }, scroll: '30s' }, received)
  end

  private

  def fail_consumer(_hit)
    raise IOError, 'consumer failed'
  end

  def page(cursor, total, ids)
    { '_scroll_id' => cursor, 'hits' => { 'total' => { 'value' => total, 'relation' => 'eq' }, 'hits' => ids.map do |id|
      { '_id' => id, '_index' => 'fm-stats-account-v1', '_source' => { 'type' => 'member', 'stat' => 0 } }
    end } }
  end

  def search_options
    { index: 'fm-stats-account', body: { 'size' => 1, 'track_total_hits' => true }, scroll: '30s' }
  end
end
