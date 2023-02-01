# frozen_string_literal: true

require_relative '../../lib/database/sequence'

StatisticIndex.create!({ id: 1, es_type_key: 'subscription', label: I18n.t('statistics.subscriptions') }) unless StatisticIndex.find_by(es_type_key: 'subscription')
StatisticIndex.create!({ id: 2, es_type_key: 'machine', label: I18n.t('statistics.machines_hours') }) unless StatisticIndex.find_by(es_type_key: 'machine')
StatisticIndex.create!({ id: 3, es_type_key: 'training', label: I18n.t('statistics.trainings') }) unless StatisticIndex.find_by(es_type_key: 'training')
StatisticIndex.create!({ id: 4, es_type_key: 'event', label: I18n.t('statistics.events') }) unless StatisticIndex.find_by(es_type_key: 'event')
StatisticIndex.create!({ id: 5, es_type_key: 'account', label: I18n.t('statistics.registrations'), ca: false }) unless StatisticIndex.find_by(es_type_key: 'account')
StatisticIndex.create!({ id: 6, es_type_key: 'project', label: I18n.t('statistics.projects'), ca: false }) unless StatisticIndex.find_by(es_type_key: 'project')
StatisticIndex.create!({ id: 7, es_type_key: 'user', label: I18n.t('statistics.users'), table: false, ca: false }) unless StatisticIndex.find_by(es_type_key: 'user')
StatisticIndex.create!({ id: 8, es_type_key: 'space', label: I18n.t('statistics.spaces') }) unless StatisticIndex.find_by(es_type_key: 'space')
StatisticIndex.create!({ id: 9, es_type_key: 'order', label: I18n.t('statistics.orders') }) unless StatisticIndex.find_by(es_type_key: 'order')

Database::Sequence.update_id_seq(StatisticIndex.table_name)


StatisticField.create!({ key: 'spaceDates', label: I18n.t('statistics.space_dates'), statistic_index_id: index.id, data_type: 'list' })
if StatisticField.count.zero?
  StatisticField.create!([
                           # available data_types : index, number, date, text, list
                           { key: 'machineDates', label: I18n.t('statistics.machine_dates'), statistic_index_id: 2, data_type: 'list' },
                           { key: 'trainingId', label: I18n.t('statistics.training_id'), statistic_index_id: 3, data_type: 'index' },
                           { key: 'trainingDate', label: I18n.t('statistics.training_date'), statistic_index_id: 3, data_type: 'date' },
                           { key: 'eventId', label: I18n.t('statistics.event_id'), statistic_index_id: 4, data_type: 'index' },
                           { key: 'eventDate', label: I18n.t('statistics.event_date'), statistic_index_id: 4, data_type: 'date' },
                           { key: 'themes', label: I18n.t('statistics.themes'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'components', label: I18n.t('statistics.components'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'machines', label: I18n.t('statistics.machines'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'name', label: I18n.t('statistics.event_name'), statistic_index_id: 4, data_type: 'text' },
                           { key: 'userId', label: I18n.t('statistics.user_id'), statistic_index_id: 7, data_type: 'index' },
                           { key: 'eventTheme', label: I18n.t('statistics.event_theme'), statistic_index_id: 4, data_type: 'text' },
                           { key: 'ageRange', label: I18n.t('statistics.age_range'), statistic_index_id: 4, data_type: 'text' }
                         ])
end

unless StatisticField.find_by(key: 'groupName').try(:label)
  field = StatisticField.find_or_initialize_by(key: 'groupName')
  field.label = 'Groupe'
  field.statistic_index_id = 1
  field.data_type = 'text'
  field.save!
end

if StatisticType.count.zero?
  StatisticType.create!([
                          { statistic_index_id: 2, key: 'booking', label: I18n.t('statistics.bookings'), graph: true, simple: true },
                          { statistic_index_id: 2, key: 'hour', label: I18n.t('statistics.hours_number'), graph: true, simple: false },
                          { statistic_index_id: 3, key: 'booking', label: I18n.t('statistics.bookings'), graph: false, simple: true },
                          { statistic_index_id: 3, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false },
                          { statistic_index_id: 4, key: 'booking', label: I18n.t('statistics.tickets_number'), graph: false,
                            simple: false },
                          { statistic_index_id: 4, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false },
                          { statistic_index_id: 5, key: 'member', label: I18n.t('statistics.users'), graph: true, simple: true },
                          { statistic_index_id: 6, key: 'project', label: I18n.t('statistics.projects'), graph: false, simple: true },
                          { statistic_index_id: 7, key: 'revenue', label: I18n.t('statistics.revenue'), graph: false, simple: false }
                        ])
end

if StatisticSubType.count.zero?
  StatisticSubType.create!([
                             { key: 'created', label: I18n.t('statistics.account_creation'),
                               statistic_types: StatisticIndex.find_by(es_type_key: 'account').statistic_types },
                             { key: 'published', label: I18n.t('statistics.project_publication'),
                               statistic_types: StatisticIndex.find_by(es_type_key: 'project').statistic_types }
                           ])
end

if StatisticGraph.count.zero?
  StatisticGraph.create!([
                           { statistic_index_id: 1, chart_type: 'stackedAreaChart', limit: 0 },
                           { statistic_index_id: 2, chart_type: 'stackedAreaChart', limit: 0 },
                           { statistic_index_id: 3, chart_type: 'discreteBarChart', limit: 10 },
                           { statistic_index_id: 4, chart_type: 'discreteBarChart', limit: 10 },
                           { statistic_index_id: 5, chart_type: 'lineChart', limit: 0 },
                           { statistic_index_id: 7, chart_type: 'discreteBarChart', limit: 10 }
                         ])
end

if StatisticCustomAggregation.count.zero?
  # available reservations hours for machines
  machine_hours = StatisticType.find_by(key: 'hour', statistic_index_id: 2)

  available_hours = StatisticCustomAggregation.new(
    statistic_type_id: machine_hours.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_hours',
    query: '{"size":0, "aggregations":{"%<aggs_name>s":{"sum":{"field":"bookable_hours"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%<start_date>s", "lte":"%<end_date>s"}}}, {"match":{"available_type":"machines"}}]}}}'
  )
  available_hours.save!

  # available training tickets
  training_bookings = StatisticType.find_by(key: 'booking', statistic_index_id: 3)

  available_tickets = StatisticCustomAggregation.new(
    statistic_type_id: training_bookings.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_tickets',
    query: '{"size":0, "aggregations":{"%<aggs_name>s":{"sum":{"field":"nb_total_places"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%<start_date>s", "lte":"%<end_date>s"}}}, {"match":{"available_type":"training"}}]}}}'
  )
  available_tickets.save!
end

unless StatisticIndex.find_by(es_type_key: 'space')
  index = StatisticIndex.create!(es_type_key: 'space', label: I18n.t('statistics.spaces'))
  StatisticType.create!([
                          { statistic_index_id: index.id, key: 'booking', label: I18n.t('statistics.bookings'),
                            graph: true, simple: true },
                          { statistic_index_id: index.id, key: 'hour', label: I18n.t('statistics.hours_number'),
                            graph: true, simple: false }
                        ])
end

unless StatisticIndex.find_by(es_type_key: 'order')
  index = StatisticIndex.create!(es_type_key: 'order', label: I18n.t('statistics.orders'))
  type = StatisticType.create!({ statistic_index_id: index.id, key: 'store', label: I18n.t('statistics.store'), graph: true, simple: true })
  StatisticSubType.create!([
                             { key: 'paid-processed', label: I18n.t('statistics.paid-processed'), statistic_types: [type] },
                             { key: 'aborted', label: I18n.t('statistics.aborted'), statistic_types: [type] }
                           ])

  # average cart price for orders
  average_cart = StatisticCustomAggregation.new(
    statistic_type_id: type.id,
    es_index: 'stats',
    es_type: 'order',
    field: 'average_cart',
    query: '{"size":0, "aggregations":{"%<aggs_name>s":{"avg":{"field":"ca", ' \
           '"script":"BigDecimal.valueOf(_value).setScale(1, RoundingMode.HALF_UP)", "missing": 0}}}, ' \
           '"query":{"bool":{"must":[{"range": {"date":{"gte":"%<start_date>s", "lte":"%<end_date>s"}}}]}}}'
  )
  average_cart.save!
end
