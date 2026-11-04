# frozen_string_literal: true

require 'test_helper'
require 'rubyXL'
require 'digest'

# Destructive ES fixtures: run only against a disposable Elasticsearch 5.6 server.
# The scenarios are kept together so the same file runs against the unmodified baseline.
# rubocop:disable Metrics/ClassLength
class SearchIndexContractTest < ActionDispatch::IntegrationTest
  FAMILIES = %w[account event machine project subscription training user space order].freeze
  VOLATILE = %w[took _shards _scroll_id _score max_score _version created_at updated_at].freeze
  class_attribute :observations, default: {}
  REFERENCE = Rails.root.join('test/fixtures/search_index/es56.json')

  setup do
    raise 'Set ES_CONTRACT_ISOLATED=1 for a disposable ES5.6 cluster' unless ENV['ES_CONTRACT_ISOLATED'] == '1'

    @client = Elasticsearch::Model.client
    assert_match(/^5\.6\./, @client.info.dig('version', 'number'))
    %w[stats fablab].each { |index| @client.indices.delete(index: index) if @client.indices.exists?(index: index) }
    @client.indices.create(index: 'stats', body: { settings: { number_of_shards: 1, number_of_replicas: 0 } })
    FAMILIES.each do |family|
      @client.indices.put_mapping(index: 'stats', type: family, body: { properties: {
                                    type: { type: 'keyword' }, subType: { type: 'keyword' }, name: { type: 'keyword' },
                                    date: { type: 'date' }, stat: { type: 'double' }, ca: { type: 'double' }, age: { type: 'integer' }
                                  } })
    end
    Availability.__elasticsearch__.create_index!
    login_as(User.with_role(:admin).first, scope: :user)
    travel_to Time.zone.parse('2026-11-03 12:00:00')
  end

  teardown do
    travel_back
    Warden.test_reset!
  end

  test 'all nine statistical families preserve identity and business types through Rails' do
    observations = FAMILIES.to_h do |family|
      source = { type: 'business-type', subType: 'opaque-subtype', stat: 0, age: nil, date: '2026-03-08',
                 userId: 2, historical: { label: 'Historique é', missingFromSql: true }, exactInteger: 9_007_199_254_740_993 }
      put_document(family, '0009007199254740993-é', source)
      refresh
      result = gateway(family, { query: { match_all: {} }, sort: ['_uid'] })
      assert_equal 1, result.dig('hits', 'total')
      assert_equal '0009007199254740993-é', result.dig('hits', 'hits', 0, '_id')
      assert_equal source.deep_stringify_keys, result.dig('hits', 'hits', 0, '_source')
      [family, normalized(result)]
    end
    capture('families', observations)
  end

  test 'legacy Stats serialization and generated IDs survive create and partial update' do
    records = FAMILIES.to_h do |family|
      attributes = { type: 'booking', date: '2026-03-08', stat: 0, age: nil, userId: 2 }
      record = if defined?(SearchIndex)
                 SearchIndex.create_stat(family: family, attributes: attributes)
               else
                 model(family).create(attributes)
               end
      assert record.persisted?
      assert_kind_of String, record.id
      refresh
      hit = gateway(family, { query: { match_all: {} } }).dig('hits', 'hits').first
      assert_equal record.id, hit['_id']
      [family, normalized(hit['_source'])]
    end
    capture('serialization', records)
  end

  test 'graphs preserve sums averages nulls zeros ranking and DST calendar buckets' do
    dates = %w[2026-03-07T23:30:00-05:00 2026-03-08T01:30:00-05:00 2026-03-08T03:30:00-04:00 2026-03-09T00:30:00-04:00]
    dates.each_with_index do |date, i|
      put_document('machine', i.to_s, type: 'hour', subType: i.even? ? 'alpha' : 'beta', date: date,
                                      stat: [0, nil, 2, 4][i], ca: [0, 10.25, nil, 20.5][i], age: [nil, 0, 20, 40][i])
    end
    refresh
    aggs = { sum: { sum: { field: 'stat' } }, average: { avg: { field: 'age' } }, empty: { avg: { field: 'unknown' } },
             ranked: { terms: { field: 'subType', order: { revenue: 'desc' } }, aggs: {
               revenue: { sum: { field: 'ca' } }, first: { top_hits: { size: 1, sort: [{ date: 'asc' }], _source: %w[date stat] } }
             } } }
    results = %w[day week month].to_h do |interval|
      query = { size: 0, query: { bool: { must: [{ term: { type: 'hour' } }, { range: { date: { gte: dates.first, lte: dates.last } } }] } },
                aggs: aggs.merge(calendar: { date_histogram: { field: 'date', interval: interval, time_zone: 'America/Toronto',
                                                               offset: '+0h', min_doc_count: 0,
                                                               extended_bounds: { min: '2026-03-06', max: '2026-03-10' } },
                                             aggs: { stat: { sum: { field: 'stat' } } } }) }
      result = gateway('machine', query)
      assert_equal 6.0, result.dig('aggregations', 'sum', 'value')
      assert_equal 20.0, result.dig('aggregations', 'average', 'value')
      assert_nil result.dig('aggregations', 'empty', 'value')
      [interval, normalized(result)]
    end
    capture('graphs', results)
  end

  test 'all stored custom aggregations execute unchanged including the average cart script' do
    put_availability('m1', available_type: 'machines', start_at: '2026-03-08', subType: ['laser'], bookable_hours: 4)
    put_availability('m2', available_type: 'machines', start_at: '2026-03-08', subType: ['mill'], bookable_hours: 2)
    put_availability('t1', available_type: 'training', start_at: '2026-03-08', nb_total_places: 6)
    [0, 10.25, nil].each_with_index { |ca, i| put_document('order', i.to_s, date: '2026-03-08', ca: ca, type: 'store') }
    refresh
    results = StatisticCustomAggregation.order(:id).to_h do |custom|
      type = custom.statistic_type
      result = gateway(type.statistic_index.es_type_key, { size: 0, aggs: { count: { sum: { field: 'stat' } } } },
                       'stat-type' => type.key, 'start-date' => '2026-03-07', 'end-date' => '2026-03-09')
      assert result.fetch('aggregations').key?(custom.field)
      [custom.field, result.fetch('aggregations').fetch(custom.field)]
    end
    capture('custom', results)
    ['{"match":{"subType":"laser"}}', '{"exclude":true,"match":{"subType":"laser"}}'].each_with_index do |filter, i|
      result = gateway('machine', { size: 0, aggs: { count: { sum: { field: 'stat' } } } },
                       'stat-type' => 'hour', 'start-date' => '2026-03-07', 'end-date' => '2026-03-09', 'custom-query' => filter)
      assert_equal [4.0, 2.0][i], result.dig('aggregations', 'available_hours', 'value')
      capture("custom-filter-#{i}", normalized(result))
    end
  end

  test 'availability worker indexes updates and idempotently deletes the SQL projection' do
    record = Availability.where(available_type: 'machines').first
    record.update!(start_at: Time.zone.parse('2026-03-08 09:00'), end_at: Time.zone.parse('2026-03-08 11:00'))
    worker = AvailabilityIndexerWorker.new
    worker.perform(:index, record.id)
    refresh
    result = @client.get(index: 'fablab', type: 'availabilities', id: record.id)['_source']
    assert_equal JSON.parse(record.as_indexed_json), result
    capture('availability', normalized(result))
    record.update!(end_at: Time.zone.parse('2026-03-08 12:00'))
    worker.perform(:index, record.id)
    assert_equal 3.0, @client.get(index: 'fablab', type: 'availabilities', id: record.id).dig('_source', 'hours_duration')
    worker.perform(:delete, record.id)
    worker.perform(:delete, record.id)
    assert_raises(Elasticsearch::Transport::Transport::Errors::NotFound) { @client.get(index: 'fablab', type: 'availabilities', id: record.id) }
  end

  test 'cleaner preserves historical documents outside inclusive date bounds across all families' do
    FAMILIES.each do |family|
      %w[2026-03-07 2026-03-08 2026-03-09].each { |date| put_document(family, date, date: date, type: 'historic', stat: 0) }
    end
    refresh
    Statistics::CleanerService.clean_stat(start_date: Date.new(2026, 3, 8), end_date: Date.new(2026, 3, 8))
    refresh
    results = FAMILIES.to_h do |family|
      result = gateway(family, { query: { match_all: {} }, sort: ['date'] })
      assert_equal %w[2026-03-07 2026-03-09], (result.dig('hits', 'hits').map { |hit| hit['_id'] })
      [family, normalized(result)]
    end
    capture('cleaner', results)
  end

  test 'cancellation deletes only the reservation family and order updates preserve historical fields' do
    slot = SlotsReservation.where(canceled_at: nil).first
    reservation = slot.reservation
    family = reservation.reservable.class.name.underscore
    put_document(family, 'cancel', reservationId: reservation.id, type: 'booking', date: '2026-03-08')
    put_document('account', 'keep', reservationId: reservation.id, type: 'member', date: '2026-03-08')
    order = Order.find(15)
    order.update!(state: 'in_progress')
    put_document('order', 'order', orderId: order.id, state: 'paid', type: 'store', subType: 'paid-processed',
                                   date: '2026-03-08', historical: 'must survive', ca: 10.25)
    refresh
    assert SlotsReservationsService.cancel(slot)
    assert_not SlotsReservationsService.cancel(slot)
    Orders::OrderService.update_state(order, User.with_role(:admin).first, 'ready')
    refresh
    assert_equal 0, gateway(family, { query: { match_all: {} } }).dig('hits', 'total')
    assert_equal 1, gateway('account', { query: { match_all: {} } }).dig('hits', 'total')
    hit = gateway('order', { query: { match_all: {} } }).dig('hits', 'hits').first
    assert_equal 'ready', hit.dig('_source', 'state')
    assert_equal 'must survive', hit.dig('_source', 'historical')
    capture('order-update', normalized(hit))
  end

  test 'disabled statistics do not run the daily builder or delete historical documents' do
    Setting.set('statistics_module', false)
    put_document('account', 'historic', date: '2026-03-08', type: 'member', stat: 1)
    StatisticWorker.new.perform
    refresh
    result = gateway('account', { query: { match_all: {} } })
    assert_equal 1, result.dig('hits', 'total')
    capture('disabled', normalized(result))
  end

  test 'real SQL builders preserve generated business documents and unrelated history' do
    order = Order.find(15)
    order.update!(created_at: Time.current, state: 'paid')
    order.order_activities.each { |activity| activity.update!(created_at: Time.current) }
    put_document('account', 'old-history', date: '1999-01-01', type: 'member', historical: 'not reconstructible')
    [Date.new(2015, 6, 1)..Date.new(2015, 6, 30), Date.new(2026, 11, 3)..Date.new(2026, 11, 3)].each do |period|
      Statistics::BuilderService.generate_statistic(start_date: period.begin.beginning_of_day, end_date: period.end.end_of_day)
    end
    refresh
    results = FAMILIES.to_h do |family|
      result = gateway(family, { size: 1000, query: { match_all: {} } })
      sources = result.dig('hits', 'hits').map { |hit| normalized(hit.fetch('_source')) }.sort_by { |source| JSON.generate(source) }
      [family, sources]
    end
    assert(results.fetch('account').any? { |source| source['historical'] == 'not reconstructible' })
    assert results.fetch('machine').any?
    assert results.fetch('order').any?
    capture('builders', results)
  end

  test 'Rails scroll pagination returns every document with numeric totals' do
    put_many(47)
    result = gateway('machine', { query: { match_all: {} }, sort: %w[date _uid], size: 7 }, 'scroll' => '30s')
    ids = []
    cursor = result['_scroll_id']
    loop do
      assert_kind_of Integer, result.dig('hits', 'total')
      hits = result.dig('hits', 'hits')
      break if hits.empty?

      ids.concat(hits.map { |hit| hit['_id'] })
      post '/_search/scroll', params: { scroll: '30s', scrollId: cursor }, as: :json
      assert_response :success
      result = JSON.parse(response.body)
      cursor = result['_scroll_id']
    end
    assert_equal 47, ids.uniq.length
    capture('pagination', ids)
  ensure
    @client.clear_scroll(scroll_id: cursor) if cursor
  end

  test 'large per-family and global XLSX exports preserve all rows beyond the result window' do
    put_many(10_037)
    snapshots = %w[machine global].to_h do |family|
      export = Export.create!(category: 'statistics', export_type: family, user: User.with_role(:admin).first,
                              query: { query: { match_all: {} }, sort: %w[date _uid], aggs: { total_stat: { sum: { field: 'stat' } },
                                                                                              total_ca: { sum: { field: 'ca' } },
                                                                                              average_age: { avg: { field: 'age' } } } }.to_json,
                              key: 'booking')
      StatisticsExportWorker.new.perform(export.id)
      book = RubyXL::Parser.parse(export.file)
      rows = workbook_rows(book)
      assert rows.values.any? { |data| data.length >= 10_038 }, 'Missing exported rows'
      assert Notification.exists?(attached_object: export)
      [family, { 'rows' => rows.transform_values(&:length), 'cells_sha256' => Digest::SHA256.hexdigest(JSON.generate(normalized(rows))) }]
    ensure
      File.delete(export.file) if export && File.exist?(export.file)
    end
    capture('exports', snapshots)
  end

  test 'Rails gates searches pagination and exports for anonymous members managers and admins' do
    outcomes = {}
    [nil, User.with_role(:member).first, User.with_role(:manager).first, User.with_role(:admin).first].each do |user|
      logout(:user)
      login_as(user, scope: :user) if user
      statuses = FAMILIES.map do |family|
        post "/stats/#{family}/_search", params: { query: { match_all: {} } }, as: :json
        assert_equal(if user&.admin?
                       200
                     else
                       (user ? 403 : 401)
                     end, response.status)
        response.status
      end
      unless user&.admin?
        post '/_search/scroll', params: { scroll: '30s', scrollId: 'not-a-cursor' }, as: :json
        assert_equal(user ? 403 : 401, response.status)
        statuses << response.status
        post '/stats/global/export', params: { body: '{}', type_key: 'booking' }, as: :json
        assert_equal(user ? 403 : 401, response.status)
        statuses << response.status
      end
      outcomes[user ? user.roles.first.name : 'anonymous'] = statuses
    end
    capture('access', outcomes)
    export = Export.create!(category: 'statistics', export_type: 'global', user: User.with_role(:member).first, query: '{}')
    assert_raises(SecurityError) { StatisticsExportWorker.new.perform(export.id) }
  end

  private

  def model(family)
    "Stats::#{family.camelize}".constantize
  end

  def workbook_rows(book)
    book.worksheets.to_h do |sheet|
      [sheet.sheet_name, sheet.sheet_data.rows.compact.map { |row| row.cells.map { |cell| cell&.value } }]
    end
  end

  def put_document(family, id, source)
    @client.index(index: 'stats', type: family, id: id, body: source)
  end

  def put_availability(id, source)
    @client.index(index: 'fablab', type: 'availabilities', id: id, body: source)
  end

  def put_many(count)
    body = count.times.flat_map do |i|
      [{ index: { _index: 'stats', _type: 'machine', _id: sprintf('%05d', i) } },
       { type: 'booking', subType: 'imprimante-3d', date: '2026-03-08', userId: 2, stat: 1, age: 20, ca: 0, name: "Machine #{i}" }]
    end
    assert_not @client.bulk(body: body)['errors']
    refresh
  end

  def refresh
    @client.indices.refresh(index: 'stats,fablab')
  end

  def gateway(family, query, parameters = {})
    path = "/stats/#{family}/_search"
    path += "?#{parameters.to_query}" if parameters.any?
    post path, params: JSON.generate(query), headers: { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
    assert_response :success
    JSON.parse(response.body)
  end

  def normalized(value)
    case value
    when Hash
      value.except(*VOLATILE).sort.to_h.transform_values { |item| normalized(item) }
    when Array
      value.map { |item| normalized(item) }
    else
      value
    end
  end

  def capture(name, value)
    value = normalized(value)
    observations[name] = value
    assert_equal JSON.parse(File.read(REFERENCE)).fetch(name), value if File.exist?(REFERENCE)
  end
end
# rubocop:enable Metrics/ClassLength

Minitest.after_run do
  path = ENV.fetch('CHARACTERIZATION_OUTPUT', nil)
  File.write(path, "#{JSON.pretty_generate(SearchIndexContractTest.observations.sort.to_h)}\n") if path
end
