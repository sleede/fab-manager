# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'
require_relative 'support'

# Live ES9 contracts, including schema safety and failure behavior.
class SearchIndexOperationsTest < ActionDispatch::IntegrationTest
  include ElasticsearchContractSupport

  setup do
    reset_search_indices
    login_as(User.with_role(:admin).first, scope: :user)
  end

  teardown { Warden.test_reset! }

  test 'schema is typeless idempotent and retains identities in every family' do
    SearchIndex::FAMILIES.each do |family|
      SearchIndex.index_document(family: family, id: '0009007199254740993', source: { type: 'business', date: '2026-03-08', stat: 0 })
    end
    2.times { SearchIndex.initialize_schema! }
    SearchIndex.refresh(family: 'all_stats')
    assert_equal 9, SearchIndex.search(family: 'all_stats', query: {}).total.fetch('value')
    SearchIndex::FAMILIES.each do |family|
      mapping = @client.indices.get_mapping(index: SearchIndex::Schema.physical(family)).body.values.first.fetch('mappings')
      assert mapping.key?('properties')
      assert_equal family, mapping.dig('_meta', 'family')
      hit = @client.get(**SearchIndex.target(family), id: '0009007199254740993')
      assert_equal 'business', hit.dig('_source', 'type')
    end
    SearchIndex.index_document(family: 'availabilities', id: 'recurring', source: { end_date: '2026-03-08T01:30:00-05:00', nb_periods: 2 })
    SearchIndex.refresh(family: 'availabilities')
    recurring = SearchIndex.search(family: 'availabilities', query: { query: { range: { end_date: { gte: '2026-03-08T06:30:00Z' } } } })
    assert_equal 1, recurring.total.fetch('value')
    assert_raises(Elastic::Transport::Transport::Errors::BadRequest) do
      SearchIndex.index_document(family: 'availabilities', id: 'invalid-recurrence', source: { end_date: 'not-a-date' })
    end
    assert SearchIndex.healthy?
  end

  test 'initialization refuses legacy data and unknown alias members without deleting them' do
    @client.indices.create(index: 'stats')
    @client.index(index: 'stats', id: 'history', body: { untouched: true })
    assert_raises(SearchIndex::SchemaConflict) { SearchIndex.initialize_schema! }
    assert_equal true, @client.get(index: 'stats', id: 'history').dig('_source', 'untouched')
    @client.indices.delete(index: 'stats')
    @client.indices.create(index: 'es-b-unknown')
    @client.indices.put_alias(index: 'es-b-unknown', name: 'fm-stats-all')
    assert_raises(SearchIndex::SchemaConflict) { SearchIndex.initialize_schema! }
    assert @client.indices.exists?(index: 'es-b-unknown')
  ensure
    %w[stats es-b-unknown].each { |index| @client.indices.delete(index: index) if @client.indices.exists?(index: index) }
  end

  test 'schema reinitialization preserves migrated legacy integer precision and source values' do
    index = SearchIndex::Schema.physical('machine')
    @client.indices.delete(index: index)
    definition = SearchIndex::Schema.definition('machine')
    %w[stat ca].each { |field| definition.fetch('mappings').fetch('properties').fetch(field)['type'] = 'long' }
    @client.indices.create(index: index, body: definition)
    2.times { SearchIndex.initialize_schema! }
    SearchIndex.index_document(family: 'machine', id: 'legacy-integer', source: { stat: 1.75, ca: 19.95, date: '2019-03-10' })
    SearchIndex.refresh(family: 'machine')
    value = @client.get(**SearchIndex.target('machine'), id: 'legacy-integer')
    assert_equal 19.95, value.dig('_source', 'ca')
    result = SearchIndex.search(family: 'machine', query: { size: 0, aggs: { stat: { sum: { field: 'stat' } } } })
    assert_equal 1.0, result.to_h.dig('aggregations', 'stat', 'value')
    assert SearchIndex::Schema.validate!(@client)
    assert_equal 'long', @client.indices.get_mapping(index: index).body.dig(index, 'mappings', 'properties', 'stat', 'type')
  end

  test 'availability setup preserves projections and accepts the explicit task ID' do
    SearchIndex.index_document(family: 'availabilities', id: 'history', source: { preserved: 'history' })
    Rails.application.load_tasks unless Rake::Task.task_defined?('fablab:es:build_availabilities_index')
    AvailabilityIndexerWorker.clear
    task = Rake::Task['fablab:es:build_availabilities_index']
    task.reenable
    task.invoke(Availability.first.id.to_s)
    assert_equal [['index', Availability.first.id.to_s]], (AvailabilityIndexerWorker.jobs.map { |job| job['args'] })
    assert_equal 'history', @client.get(**SearchIndex.target('availabilities'), id: 'history').dig('_source', 'preserved')
  end

  test 'cleaner crosses three date batches without deleting outside bounds' do
    first = Date.new(2020, 1, 1)
    last = first + 2050
    dates = [first - 1, first, first + 1024, last, last + 1]
    SearchIndex::STAT_FAMILIES.each do |family|
      dates.each { |date| SearchIndex.index_document(family: family, id: date.iso8601, source: { date: date.iso8601, type: 'historic' }) }
    end
    SearchIndex.refresh(family: 'all_stats')
    Statistics::CleanerService.clean_stat(start_date: first, end_date: last)
    SearchIndex.refresh(family: 'all_stats')
    SearchIndex::STAT_FAMILIES.each do |family|
      assert_equal [first.prev_day.iso8601, last.next_day.iso8601],
                   (SearchIndex.search(family: family, query: { sort: ['date'] }).hits.map { |hit| hit.fetch('id') })
    end
  end

  test 'order update reaches all pages and retains historical fields' do
    order = Order.find(15)
    order.update!(state: 'paid')
    23.times do |i|
      SearchIndex.index_document(family: 'order', id: "order-#{i}",
                                 source: { orderId: order.id, type: 'store', ca: 0, historical: i, state: 'paid', subType: 'paid-processed' })
    end
    SearchIndex.refresh(family: 'order')
    Orders::OrderService.update_state(order, User.with_role(:admin).first, 'ready')
    SearchIndex.refresh(family: 'order')
    hits = SearchIndex.each_hit(family: 'order', query: {}).to_a
    assert_equal (0...23).to_a, hits.map { |hit| hit.dig('_source', 'historical') }.sort
    assert(hits.all? { |hit| hit.dig('_source', 'state') == 'ready' })
  end

  test 'empty successful and interrupted exports release their scroll contexts' do
    13.times { |i| SearchIndex.create_stat(family: 'account', attributes: { type: 'member', stat: i, date: '2026-03-08' }) }
    SearchIndex.refresh(family: 'account')
    before = open_contexts
    result = SearchIndex.export(family: 'account', query: { size: 0 })
    assert_equal 13, result.dig('hits', 'hits').length
    result = SearchIndex.export(family: 'account', query: { query: { term: { type: 'missing' } } })
    assert_equal 0, result.dig('hits', 'total')
    assert_empty result.dig('hits', 'hits')
    assert_raises(IOError) { SearchIndex.each_hit(family: 'account', query: {}, page_size: 2) { |hit| raise IOError if hit } }
    assert_operator open_contexts, :<=, before
  end

  test 'bulk inspects item failures and exposes partial success without pretending to be atomic' do
    docs = [{ id: 'valid', source: { date: '2026-03-08', type: 'member' } }, { id: 'invalid', source: { date: 'not-a-date' } }]
    error = assert_raises(SearchIndex::BulkFailure) { SearchIndex.bulk_index(family: 'account', documents: docs) }
    assert_equal [201, 400], (error.items.map { |item| item.fetch('index').fetch('status') })
    assert_equal 'member', @client.get(**SearchIndex.target('account'), id: 'valid').dig('_source', 'type')
    assert_raises(Elastic::Transport::Transport::Errors::NotFound) { @client.get(**SearchIndex.target('account'), id: 'invalid') }
  end

  test 'Rails rejects arbitrary targets scripts lookups and unsigned or expired cursors' do
    post '/stats/machine/_search', params: '{broken', headers: { 'Content-Type' => 'application/json' }
    assert_response :unprocessable_entity
    post '/stats/machine/_search?index=other', params: { query: { match_all: {} } }, as: :json
    assert_response :unprocessable_entity
    post '/stats/machine/_search', params: { size: -1 }, as: :json
    assert_response :unprocessable_entity
    post '/stats/machine/_search', params: { query: { terms: { userId: { index: 'other', id: '1', path: 'ids' } } } }, as: :json
    assert_response :unprocessable_entity
    post '/stats/machine/_search', params: { aggs: { a: { avg: { script: 'return 42' } } } }, as: :json
    assert_response :unprocessable_entity
    [{ query: { bool: nil } }, { aggs: [] }, { sort: [{ _script: { script: 'return 42', type: 'number' } }] },
     { aggs: { a: { top_hits: { script_fields: { x: { script: 'return 42' } } } } } }].each do |body|
      post '/stats/machine/_search', params: body, as: :json
      assert_response :unprocessable_entity
    end
    post '/_search/scroll', params: { scrollId: 'raw-es-cursor', scroll: '30s' }, as: :json
    assert_response :gone
    token = Rails.application.message_verifier('statistics-scroll').generate('cursor', purpose: 'statistics', expires_in: -1)
    delete '/_search/scroll', params: { scrollId: token }, as: :json
    assert_response :gone
  end

  test 'keyword aggregations preserve analyzed filters and date histogram intervals' do
    SearchIndex.index_document(
      family: 'project', id: 'custom',
      source: { type: 'project', groupName: 'Standard Association', customField: 'Custom Text',
                exactInteger: 9_007_199_254_740_993, date: '2026-03-08' }
    )
    SearchIndex.refresh(family: 'project')
    result = SearchIndex.search(
      family: 'project',
      query: { query: { match: { groupName: 'association' } }, sort: ['groupName'],
               aggs: { groups: { terms: { field: 'groupName' } }, custom: { terms: { field: 'customField.keyword' } } } }
    ).legacy_response
    assert_equal 1, result.dig('hits', 'total')
    assert_equal 9_007_199_254_740_993, result.dig('hits', 'hits', 0, '_source', 'exactInteger')
    assert_equal 'Standard Association', result.dig('aggregations', 'groups', 'buckets', 0, 'key')
    assert_equal 'Custom Text', result.dig('aggregations', 'custom', 'buckets', 0, 'key')
  end

  private

  def open_contexts
    @client.nodes.stats(metric: 'indices', index_metric: 'search').body.fetch('nodes').values.sum do |node|
      node.dig('indices', 'search', 'open_contexts')
    end
  end
end
