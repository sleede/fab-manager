# frozen_string_literal: true

require_relative '../../lib/database/sequence'

# statistic_indices
unless StatisticIndex.find_by(es_type_key: 'subscription')
  StatisticIndex.create!({ id: 1, es_type_key: 'subscription', label: I18n.t('statistics.subscriptions') })
end
unless StatisticIndex.find_by(es_type_key: 'machine')
  StatisticIndex.create!({ id: 2, es_type_key: 'machine', label: I18n.t('statistics.machines_hours') })
end
unless StatisticIndex.find_by(es_type_key: 'training')
  StatisticIndex.create!({ id: 3, es_type_key: 'training', label: I18n.t('statistics.trainings') })
end
StatisticIndex.create!({ id: 4, es_type_key: 'event', label: I18n.t('statistics.events') }) unless StatisticIndex.find_by(es_type_key: 'event')
unless StatisticIndex.find_by(es_type_key: 'account')
  StatisticIndex.create!({ id: 5, es_type_key: 'account', label: I18n.t('statistics.registrations'), ca: false })
end
unless StatisticIndex.find_by(es_type_key: 'project')
  StatisticIndex.create!({ id: 6, es_type_key: 'project', label: I18n.t('statistics.projects'), ca: false })
end
unless StatisticIndex.find_by(es_type_key: 'user')
  StatisticIndex.create!({ id: 7, es_type_key: 'user', label: I18n.t('statistics.users'), table: false, ca: false })
end
Database::Sequence.update_id_seq(StatisticIndex.table_name)
StatisticIndex.create!({ es_type_key: 'space', label: I18n.t('statistics.spaces') }) unless StatisticIndex.find_by(es_type_key: 'space')
StatisticIndex.create!({ es_type_key: 'order', label: I18n.t('statistics.orders') }) unless StatisticIndex.find_by(es_type_key: 'order')

statistic_index_space = StatisticIndex.find_by(es_type_key: 'space')
statistic_index_order = StatisticIndex.find_by(es_type_key: 'order')

# statistic_fields
unless StatisticField.find_by(key: 'spaceDates')
  StatisticField.create!({ key: 'spaceDates', label: I18n.t('statistics.space_dates'),
                           statistic_index_id: statistic_index_space.id, data_type: 'list' })
end
unless StatisticField.find_by(key: 'machineDates')
  StatisticField.create!({ key: 'machineDates', label: I18n.t('statistics.machine_dates'), statistic_index_id: 2, data_type: 'list' })
end
unless StatisticField.find_by(key: 'trainingId')
  StatisticField.create!({ key: 'trainingId', label: I18n.t('statistics.training_id'), statistic_index_id: 3, data_type: 'index' })
end
unless StatisticField.find_by(key: 'trainingDate')
  StatisticField.create!({ key: 'trainingDate', label: I18n.t('statistics.training_date'), statistic_index_id: 3, data_type: 'date' })
end
unless StatisticField.find_by(key: 'eventId')
  StatisticField.create!({ key: 'eventId', label: I18n.t('statistics.event_id'), statistic_index_id: 4, data_type: 'index' })
end
unless StatisticField.find_by(key: 'eventDate')
  StatisticField.create!({ key: 'eventDate', label: I18n.t('statistics.event_date'), statistic_index_id: 4, data_type: 'date' })
end
unless StatisticField.find_by(key: 'themes')
  StatisticField.create!({ key: 'themes', label: I18n.t('statistics.themes'), statistic_index_id: 6, data_type: 'list' })
end
unless StatisticField.find_by(key: 'components')
  StatisticField.create!({ key: 'components', label: I18n.t('statistics.components'), statistic_index_id: 6, data_type: 'list' })
end
unless StatisticField.find_by(key: 'machines')
  StatisticField.create!({ key: 'machines', label: I18n.t('statistics.machines'), statistic_index_id: 6, data_type: 'list' })
end
unless StatisticField.find_by(key: 'name')
  StatisticField.create!({ key: 'name', label: I18n.t('statistics.event_name'), statistic_index_id: 4, data_type: 'text' })
end
unless StatisticField.find_by(key: 'userId')
  StatisticField.create!({ key: 'userId', label: I18n.t('statistics.user_id'), statistic_index_id: 7, data_type: 'index' })
end
unless StatisticField.find_by(key: 'eventTheme')
  StatisticField.create!({ key: 'eventTheme', label: I18n.t('statistics.event_theme'), statistic_index_id: 4, data_type: 'text' })
end
unless StatisticField.find_by(key: 'ageRange')
  StatisticField.create!({ key: 'ageRange', label: I18n.t('statistics.age_range'), statistic_index_id: 4, data_type: 'text' })
end
unless StatisticField.find_by(key: 'groupName')
  StatisticField.create!({ key: 'groupName', label: I18n.t('statistics.group'), statistic_index_id: 1, data_type: 'text' })
end

# statistic_types
unless StatisticType.find_by(key: 'booking', statistic_index_id: 2)
  StatisticType.create!({ statistic_index_id: 2, key: 'booking', label: I18n.t('statistics.bookings'), graph: true, simple: true })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: 2)
  StatisticType.create!({ statistic_index_id: 2, key: 'hour', label: I18n.t('statistics.hours_number'), graph: true, simple: false })
end
unless StatisticType.find_by(key: 'booking', statistic_index_id: 3)
  StatisticType.create!({ statistic_index_id: 3, key: 'booking', label: I18n.t('statistics.bookings'), graph: false, simple: true })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: 3)
  StatisticType.create!({ statistic_index_id: 3, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false })
end
unless StatisticType.find_by(key: 'booking', statistic_index_id: 4)
  StatisticType.create!({ statistic_index_id: 4, key: 'booking', label: I18n.t('statistics.tickets_number'), graph: false, simple: false })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: 4)
  StatisticType.create!({ statistic_index_id: 4, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false })
end
unless StatisticType.find_by(key: 'member', statistic_index_id: 5)
  StatisticType.create!({ statistic_index_id: 5, key: 'member', label: I18n.t('statistics.users'), graph: true, simple: true })
end
unless StatisticType.find_by(key: 'project', statistic_index_id: 6)
  StatisticType.create!({ statistic_index_id: 6, key: 'project', label: I18n.t('statistics.projects'), graph: false, simple: true })
end
unless StatisticType.find_by(key: 'revenue', statistic_index_id: 7)
  StatisticType.create!({ statistic_index_id: 7, key: 'revenue', label: I18n.t('statistics.revenue'), graph: false, simple: false })
end
unless StatisticType.find_by(key: 'booking', statistic_index_id: statistic_index_space.id)
  StatisticType.create!({ statistic_index_id: statistic_index_space.id, key: 'booking', label: I18n.t('statistics.bookings'),
                          graph: true, simple: true })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: statistic_index_space.id)
  StatisticType.create!({ statistic_index_id: statistic_index_space.id, key: 'hour', label: I18n.t('statistics.hours_number'),
                          graph: true, simple: false })
end
unless StatisticType.find_by(key: 'store', statistic_index_id: statistic_index_order.id)
  StatisticType.create!({ statistic_index_id: statistic_index_order.id, key: 'store', label: I18n.t('statistics.store'),
                          graph: true, simple: true })
end
Plan.find_each do |plan|
  if plan.find_statistic_type.nil?
    StatisticType.create!(
      statistic_index_id: 1,
      key: plan.duration.to_i,
      label: "#{I18n.t('statistics.duration')} : #{plan.human_readable_duration}",
      graph: true,
      simple: true
    )
  end
end

# statistic_sub_types
unless StatisticSubType.find_by(key: 'created')
  StatisticSubType.create!({ key: 'created', label: I18n.t('statistics.account_creation'),
                             statistic_types: StatisticIndex.find_by(es_type_key: 'account').statistic_types })
end
unless StatisticSubType.find_by(key: 'published')
  StatisticSubType.create!({ key: 'published', label: I18n.t('statistics.project_publication'),
                             statistic_types: StatisticIndex.find_by(es_type_key: 'project').statistic_types })
end
unless StatisticSubType.find_by(key: 'paid-processed')
  StatisticSubType.create!({ key: 'paid-processed', label: I18n.t('statistics.paid-processed'),
                             statistic_types: statistic_index_order.statistic_types })
end
unless StatisticSubType.find_by(key: 'aborted')
  StatisticSubType.create!({ key: 'aborted', label: I18n.t('statistics.aborted'), statistic_types: statistic_index_order.statistic_types })
end
Plan.find_each do |plan|
  type = plan.find_statistic_type
  subtype = if StatisticSubType.find_by(key: plan.slug).nil?
              StatisticSubType.create!(key: plan.slug, label: plan.name)
            else
              StatisticSubType.find_by(key: plan.slug)
            end

  if StatisticTypeSubType.find_by(statistic_type: type, statistic_sub_type: subtype).nil?
    StatisticTypeSubType.create!(statistic_type: type, statistic_sub_type: subtype)
  end
end

# statistic_graphs
StatisticGraph.create!({ statistic_index_id: 1, chart_type: 'stackedAreaChart', limit: 0 }) unless StatisticGraph.find_by(statistic_index_id: 1)
StatisticGraph.create!({ statistic_index_id: 2, chart_type: 'stackedAreaChart', limit: 0 }) unless StatisticGraph.find_by(statistic_index_id: 2)
StatisticGraph.create!({ statistic_index_id: 3, chart_type: 'discreteBarChart', limit: 10 }) unless StatisticGraph.find_by(statistic_index_id: 3)
StatisticGraph.create!({ statistic_index_id: 4, chart_type: 'discreteBarChart', limit: 10 }) unless StatisticGraph.find_by(statistic_index_id: 4)
StatisticGraph.create!({ statistic_index_id: 5, chart_type: 'lineChart', limit: 0 }) unless StatisticGraph.find_by(statistic_index_id: 5)
StatisticGraph.create!({ statistic_index_id: 7, chart_type: 'discreteBarChart', limit: 10 }) unless StatisticGraph.find_by(statistic_index_id: 7)

# statistic_custom_aggregations
unless StatisticCustomAggregation.find_by(es_type: 'availabilities', field: 'available_hours')
  # available reservations hours for machines
  machine_hours = StatisticType.find_by(key: 'hour', statistic_index_id: 2)

  StatisticCustomAggregation.create!(
    statistic_type_id: machine_hours.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_hours',
    query: '{"size":0, "aggregations":{"%<aggs_name>s":{"sum":{"field":"bookable_hours"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%<start_date>s", "lte":"%<end_date>s"}}}, {"match":{"available_type":"machines"}}]}}}'
  )
end
unless StatisticCustomAggregation.find_by(es_type: 'availabilities', field: 'available_tickets')
  # available training tickets
  training_bookings = StatisticType.find_by(key: 'booking', statistic_index_id: 3)

  StatisticCustomAggregation.create!(
    statistic_type_id: training_bookings.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_tickets',
    query: '{"size":0, "aggregations":{"%<aggs_name>s":{"sum":{"field":"nb_total_places"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%<start_date>s", "lte":"%<end_date>s"}}}, {"match":{"available_type":"training"}}]}}}'
  )
end
unless StatisticCustomAggregation.find_by(es_type: 'order', field: 'average_cart')
  # available training tickets
  order_store = StatisticType.find_by(key: 'store', statistic_index_id: statistic_index_order.id)
  # average cart price for orders
  StatisticCustomAggregation.create!(
    statistic_type_id: order_store.id,
    es_index: 'stats',
    es_type: 'order',
    field: 'average_cart',
    query: '{"size":0, "aggregations":{"%<aggs_name>s":{"avg":{"field":"ca", ' \
           '"script":"BigDecimal.valueOf(_value).setScale(1, RoundingMode.HALF_UP)", "missing": 0}}}, ' \
           '"query":{"bool":{"must":[{"range": {"date":{"gte":"%<start_date>s", "lte":"%<end_date>s"}}}]}}}'
  )
end
