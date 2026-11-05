# frozen_string_literal: true

# Explicit destructive fixture, run with rails runner only on the disposable rehearsal.
# The end-to-end fixture intentionally keeps each phase sequential and its payloads visible.
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Layout/LineLength
raise 'Disposable rehearsal only' unless Rails.env.test? && ENV['ES_CONTRACT_ISOLATED'] == '1'

require 'digest'
require 'rubyXL'
require 'action_dispatch/testing/integration'
require 'warden/test/helpers'
require 'active_support/testing/time_helpers'
require 'sidekiq/api'

class ElasticsearchRehearsal
  include Warden::Test::Helpers
  include ActiveSupport::Testing::TimeHelpers

  FAMILIES = %w[account event machine project subscription training user space order].freeze

  def client
    defined?(SearchIndex::Connection) ? SearchIndex::Connection.client : Elasticsearch::Model.client
  end

  def refresh
    SearchIndex.refresh(family: 'all_stats')
    SearchIndex.refresh(family: 'availabilities')
  end

  def session(user)
    Warden.test_mode!
    logout(:user)
    login_as(user, scope: :user) if user
    ActionDispatch::Integration::Session.new(Rails.application)
  end

  def query(user, family, body, parameters = {})
    request = session(user)
    path = "/stats/#{family}/_search"
    path += "?#{parameters.to_query}" if parameters.any?
    request.post(path, params: JSON.generate(body), headers: { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' })
    [request.response.status, request.response.body.blank? ? {} : JSON.parse(request.response.body)]
  end

  def require_value(condition, message)
    raise message unless condition
  end

  def put_document(family, identity, source)
    if SearchIndex.respond_to?(:index_document)
      SearchIndex.index_document(family: family, id: identity, source: source)
    else
      client.index(**SearchIndex.target(family), id: identity, body: source)
    end
  end

  def seed
    require_value(Gem.loaded_specs.fetch('elasticsearch').version.to_s.start_with?('5.'), 'Seed must use the unchanged ES5 business code')
    Setting.set('statistics_module', true)
    SearchIndex.rebuild_statistics!
    SearchIndex.ensure_availability_mapping
    User.members.order(:id).last.add_role(:manager) if User.with_role(:manager).none?
    order = Order.find(15)
    travel_to(Time.zone.parse('2026-11-03 12:00:00')) do
      order.update!(created_at: Time.current, state: 'paid')
      order.order_activities.each { |activity| activity.update!(created_at: Time.current) }
      [Date.new(2015, 6, 1)..Date.new(2015, 6, 30), Date.new(2026, 11, 3)..Date.new(2026, 11, 3)].each do |period|
        Statistics::BuilderService.generate_statistic(start_date: period.begin.beginning_of_day, end_date: period.end.end_of_day)
      end
    end
    user = User.find(2)
    FAMILIES.each do |family|
      record = SearchIndex.create_stat(family: family, attributes: { type: 'booking', subType: 'historical', date: '2019-03-10',
                                                                     stat: 0, userId: user.id, group: user.group.slug, groupName: user.group.name, age: 0 })
      require_value(record.persisted?, "Missing real #{family} model")
      put_document(family, 'shared-history-id', { type: 'historical-business-type',
                                                  subType: 'historical', date: '2019-03-10T01:30:00-05:00', userId: user.id, groupName: user.group.name,
                                                  gender: user.statistic_profile.gender, stat: 0, ca: 19.5, nullable: nil, exactInteger: 9_007_199_254_740_993 })
    end
    Availability.find_each { |record| AvailabilityIndexerWorker.new.perform(:index, record.id) }
    # More than the result window, produced through the reference application boundary.
    10_037.times.each_slice(500) do |numbers|
      documents = numbers.map do |number|
        { id: sprintf('export-%05d', number), source: { type: 'booking', subType: 'export', date: '2019-03-10',
                                                        stat: 1, ca: 0, age: 20, userId: user.id, groupName: user.group.name, name: 'Reference machine' } }
      end
      response = client.bulk(body: documents.flat_map { |doc| [{ index: { _index: 'stats', _type: 'machine', _id: doc[:id] } }, doc[:source]] })
      require_value(!response['errors'], 'Reference bulk fixture failed')
    end
    refresh
    before = query(User.with_role(:admin).first, 'machine', { query: { term: { _id: 'shared-history-id' } } })[1]
    historical = before.fetch('hits').fetch('hits').first.fetch('_source')
    File.write('/evidence/historical-original.json', JSON.pretty_generate(historical))
    user.group.update!(name: 'Group changed AFTER historical generation')
    user.profile.update!(first_name: 'Profile changed AFTER history')
    user.statistic_profile.update!(gender: !user.statistic_profile.gender)
    after = query(User.with_role(:admin).first, 'machine', { query: { term: { _id: 'shared-history-id' } } })[1]
    require_value(after.fetch('hits').fetch('hits').first.fetch('_source') == historical, 'Changing SQL profiles rewrote ES history')
    Setting.set('statistics_module', false)
    StatisticWorker.new.perform
    refresh
    require_value(query(User.with_role(:admin).first, 'machine', { size: 0 })[1].dig('hits', 'total') > 10_000,
                  'Disabled statistics deleted history')
    Setting.set('statistics_module', true)
    { seeded: true, profile_changed_after_history: true,
      total_machine: query(User.with_role(:admin).first, 'machine', { size: 0 })[1].dig('hits', 'total') }
  end

  def observe
    refresh
    admin = User.with_role(:admin).first
    result = { families: {}, permissions: {}, custom: {} }
    FAMILIES.each do |family|
      status, value = query(admin, family, { size: 0, aggs: { stat: { sum: { field: 'stat' } }, ca: { sum: { field: 'ca' } },
                                                              dates: { date_histogram: { field: 'date', interval: 'month', time_zone: 'America/Toronto' } } } })
      require_value(status == 200, "Search #{family} HTTP #{status}")
      result[:families][family] = { total: value.dig('hits', 'total'), aggregations: value['aggregations'] }
    end
    [nil, User.with_role(:member).first, User.with_role(:manager).first, admin].each do |user|
      role = if user
               if user.admin?
                 'admin'
               else
                 user.manager? ? 'manager' : 'member'
               end
             else
               'anonymous'
             end
      expected = if user&.admin?
                   200
                 else
                   (user ? 403 : 401)
                 end
      statuses = FAMILIES.map { |family| query(user, family, { size: 0 })[0] }
      require_value(statuses.all? { |status| status == expected }, "Wrong #{role} policy")
      result[:permissions][role] = statuses
    end
    StatisticCustomAggregation.order(:id).each do |custom|
      family = custom.statistic_type.statistic_index.es_type_key
      status, value = query(admin, family, { size: 0, aggs: { count: { sum: { field: 'stat' } } } }, 'stat-type' => custom.statistic_type.key,
                                                                                                     'start-date' => '1900-01-01', 'end-date' => '2100-01-01')
      require_value(status == 200, "Custom #{custom.field} failed")
      result[:custom][custom.field] = value.fetch('aggregations').fetch(custom.field)
    end
    result[:filters] = [false, true].map do |exclude|
      status, value = query(admin, 'machine', { size: 0, aggs: { count: { sum: { field: 'stat' } } } }, 'stat-type' => 'hour', 'start-date' => '1900-01-01',
                                                                                                        'end-date' => '2100-01-01', 'custom-query' => { exclude: exclude, match: { subType: 'historical' } }.to_json)
      require_value(status == 200, 'Custom filter failed')
      value.fetch('aggregations')
    end
    result[:exports] = %w[machine global].to_h do |family|
      export = Export.create!(category: 'statistics', export_type: family, user: admin, key: 'booking',
                              query: { query: { term: { subType: 'export' } }, sort: %w[date _uid],
                                       aggs: { total_stat: { sum: { field: 'stat' } }, total_ca: { sum: { field: 'ca' } }, average_age: { avg: { field: 'age' } } } }.to_json)
      StatisticsExportWorker.new.perform(export.id)
      book = RubyXL::Parser.parse(export.file)
      rows = book.worksheets.to_h do |sheet|
        [sheet.sheet_name, sheet.sheet_data.rows.compact.map do |row|
                             row.cells.map do |cell|
                               cell&.value
                             end
                           end]
      end
      require_value(rows.values.any? { |data| data.length >= 10_038 }, 'Export lost rows beyond one page')
      [family, { rows: rows.transform_values(&:length), cells_sha256: Digest::SHA256.hexdigest(JSON.generate(rows)) }]
    end
    status, historical = query(admin, 'machine', { query: { term: { _id: 'shared-history-id' } } })
    require_value(status == 200, 'Cannot read imported historical record')
    actual = historical.fetch('hits').fetch('hits').first.fetch('_source')
    original = JSON.parse(File.read('/evidence/historical-original.json'))
    require_value(actual == original, 'Historical record regenerated using the changed SQL profile')
    result[:history_preserved] = actual
    result[:client] = { version: Gem.loaded_specs.fetch('elasticsearch').version.to_s,
                        legacy_integrations: Gem.loaded_specs.keys.grep(/elasticsearch-(?:model|persistence|rails|transport)/).sort }
    result
  ensure
    Warden.test_reset!
  end

  def post_cutover
    require_value(defined?(SearchIndex::Connection).present?, 'Target code required')
    record = Availability.where(available_type: 'machines').first
    worker = AvailabilityIndexerWorker.new
    worker.perform(:index, record.id)
    record.update!(end_at: record.end_at + 1.hour)
    worker.perform(:index, record.id)
    require_value(
      client.get(**SearchIndex.target('availabilities'), id: record.id).dig('_source',
                                                                            'hours_duration') == JSON.parse(record.as_indexed_json)['hours_duration'], 'Availability update lost'
    )
    worker.perform(:delete, record.id)
    worker.perform(:index, record.id)
    slot = SlotsReservation.where(canceled_at: nil).first
    reservation = slot.reservation
    family = reservation.reservable.class.name.underscore
    SearchIndex.index_document(family: family, id: 'after-switch-cancel', source: { reservationId: reservation.id, date: '2026-11-05' })
    refresh
    require_value(SlotsReservationsService.cancel(slot), 'Reservation cancellation failed')
    order = Order.find(15)
    order.update!(state: 'in_progress')
    Orders::OrderService.update_state(order, User.with_role(:admin).first, 'ready')
    refresh
    require_value(!client.exists?(**SearchIndex.target(family), id: 'after-switch-cancel'), 'Reservation stat deletion failed')
    require_value(client.get(**SearchIndex.target('machine'), id: 'shared-history-id').dig('_source', 'type') == 'historical-business-type',
                  'Business type lost')
    require_value(Gem.loaded_specs.keys.none? do |name|
                    name.match?(/elasticsearch-(?:model|persistence|rails|transport)/)
                  end, 'Old Elasticsearch integration loaded')
    { availability_updated: true, reservation_canceled: true, order_state: order.reload.state, old_integrations_loaded: false }
  end

  def mutate_profiles
    user = User.find(2)
    original = JSON.parse(File.read('/evidence/historical-original.json'))
    user.group.update!(name: 'Validated group update AFTER history')
    user.profile.update!(first_name: 'Validated profile update AFTER history')
    user.statistic_profile.update!(gender: !original.fetch('gender'))
    refresh
    current = query(User.with_role(:admin).first, 'machine', { query: { term: { _id: 'shared-history-id' } } })[1]
    require_value(current.fetch('hits').fetch('hits').first.fetch('_source') == original, 'Validated profile updates replaced ES history')
    { validated_group_update: true, validated_profile_update: true, original_history_unchanged: true }
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Layout/LineLength

mode = ENV.fetch('ES_REHEARSAL_STEP')
result = ElasticsearchRehearsal.new.public_send(mode)
File.write(ENV.fetch('ES_REHEARSAL_OUTPUT'), JSON.pretty_generate(result))
puts "Rehearsal #{mode} completed"
