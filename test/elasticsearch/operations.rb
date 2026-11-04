# frozen_string_literal: true

require 'test_helper'

# Live contracts for administrative operations and complete cursor consumers.
class SearchIndexOperationsTest < ActiveSupport::TestCase
  setup do
    raise 'Set ES_CONTRACT_ISOLATED=1 for disposable ES5.6 services' unless ENV['ES_CONTRACT_ISOLATED'] == '1'

    @client = Elasticsearch::Model.client
    assert_match(/^5\.6\./, @client.info.dig('version', 'number'))
    SearchIndex.rebuild_statistics!
  end

  test 'rebuild keeps the eight explicit mappings and every Stats model remains writable' do
    mappings = @client.indices.get_mapping(index: 'stats').fetch('stats').fetch('mappings')
    assert_equal (SearchIndex::STAT_FAMILIES - ['order']).sort, mappings.keys.sort
    SearchIndex::STAT_FAMILIES.each do |family|
      assert_equal 'date', mappings.dig(family, 'properties', 'date', 'type') unless family == 'order'
      record = SearchIndex.create_stat(family: family, attributes: { type: 'member', date: '2026-03-08', stat: 0 })
      assert record.persisted?
    end
    SearchIndex.refresh(family: 'all_stats')
    assert_equal 9, SearchIndex.search(family: 'all_stats', query: {}).total.fetch('value')
    assert SearchIndex.healthy?
  end

  test 'availability mapping is repeatable preserves documents and task uses its explicit ID' do
    SearchIndex.ensure_availability_mapping
    @client.index(index: 'fablab', type: 'availabilities', id: 'boundary-history', body: { preserved: 'history' })
    @client.index(index: 'fablab', type: 'another_type', id: 'boundary-other', body: { preserved: 'other' })
    2.times { SearchIndex.ensure_availability_mapping }
    assert_equal 'history', @client.get(index: 'fablab', type: 'availabilities', id: 'boundary-history').dig('_source', 'preserved')
    assert_equal 'other', @client.get(index: 'fablab', type: 'another_type', id: 'boundary-other').dig('_source', 'preserved')
    Rails.application.load_tasks unless Rake::Task.task_defined?('fablab:es:build_availabilities_index')
    AvailabilityIndexerWorker.clear
    task = Rake::Task['fablab:es:build_availabilities_index']
    task.reenable
    task.invoke(Availability.first.id.to_s)
    assert_equal [['index', Availability.first.id.to_s]], (AvailabilityIndexerWorker.jobs.map { |job| job['args'] })
  end

  test 'cleaner crosses multiple 1024-date batches without deleting outside bounds' do
    first = Date.new(2020, 1, 1)
    last = first + 2050
    dates = [first - 1, first, first + 1024, last, last + 1]
    SearchIndex::STAT_FAMILIES.each do |family|
      dates.each { |date| @client.index(index: 'stats', type: family, id: date.iso8601, body: { date: date.iso8601, type: 'historic' }) }
    end
    SearchIndex.refresh(family: 'all_stats')
    Statistics::CleanerService.clean_stat(start_date: first, end_date: last)
    SearchIndex.refresh(family: 'all_stats')
    SearchIndex::STAT_FAMILIES.each do |family|
      assert_equal [first.prev_day.iso8601, last.next_day.iso8601],
                   (SearchIndex.search(family: family, query: { sort: ['date'] }).hits.map { |hit| hit.fetch('id') })
    end
  end

  test 'order state updates every historical document beyond the default search page' do
    order = Order.find(15)
    order.update!(state: 'paid')
    23.times do |i|
      @client.index(index: 'stats', type: 'order', id: "boundary-order-#{i}",
                    body: { orderId: order.id, type: 'store', ca: 0, historical: i, state: 'paid', subType: 'paid-processed' })
    end
    SearchIndex.refresh(family: 'order')
    Orders::OrderService.update_state(order, User.with_role(:admin).first, 'ready')
    SearchIndex.refresh(family: 'order')
    hits = SearchIndex.each_hit(family: 'order', query: {}).to_a
    assert_equal 23, hits.length
    assert_equal [*0...23], hits.map { |hit| hit.dig('_source', 'historical') }.sort
    assert(hits.all? { |hit| hit.dig('_source', 'state') == 'ready' && hit.dig('_source', 'subType') == 'paid-processed' })
  end

  test 'empty and interrupted exports do not retain live search contexts' do
    13.times { |i| SearchIndex.create_stat(family: 'account', attributes: { type: 'member', stat: i, date: '2026-03-08' }) }
    SearchIndex.refresh(family: 'account')
    before = open_contexts
    result = SearchIndex.export(family: 'account', query: { query: { match_all: {} } })
    assert_equal 13, result.dig('hits', 'total')
    assert_equal 13, result.dig('hits', 'hits').length
    result = SearchIndex.export(family: 'account', query: { query: { term: { type: 'missing-type' } } })
    assert_equal 0, result.dig('hits', 'total')
    assert_empty result.dig('hits', 'hits')
    assert_raises(IOError) { SearchIndex.each_hit(family: 'account', query: {}, page_size: 2, &method(:fail_consumer)) }
    assert_operator open_contexts, :<=, before
  end

  test 'global export keeps documents of stored types outside the catalogue' do
    SearchIndex.create_stat(family: 'machine', attributes: { type: 'booking', stat: 1, date: '2026-03-08' })
    @client.index(index: 'stats', type: 'site_specific', id: 'legacy', body: { type: 'custom', date: '2026-03-08' })
    SearchIndex.refresh(family: 'all_stats')
    result = SearchIndex.export(family: 'all_stats', query: { query: { match_all: {} } })
    assert_equal %w[machine site_specific], result.dig('hits', 'hits').map { |hit| hit['_type'] }.sort
  end

  private

  def fail_consumer(_hit)
    raise IOError, 'Interrupted export'
  end

  def open_contexts
    @client.perform_request('GET', '_nodes/stats/indices/search').body.fetch('nodes').values.sum do |node|
      node.dig('indices', 'search', 'open_contexts')
    end
  end
end
