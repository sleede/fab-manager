# frozen_string_literal: true

require_relative '../../lib/database/sequence'

# statistic_indices
unless StatisticIndex.find_by(es_type_key: 'subscription')
  StatisticIndex.create!({ id: 1, es_type_key: 'subscription', label_i18n_path: 'statistics.subscriptions' })
end
unless StatisticIndex.find_by(es_type_key: 'machine')
  StatisticIndex.create!({ id: 2, es_type_key: 'machine', label_i18n_path: 'statistics.machines_hours' })
end
unless StatisticIndex.find_by(es_type_key: 'training')
  StatisticIndex.create!({ id: 3, es_type_key: 'training', label_i18n_path: 'statistics.trainings' })
end
StatisticIndex.create!({ id: 4, es_type_key: 'event', label_i18n_path: 'statistics.events' }) unless StatisticIndex.find_by(es_type_key: 'event')
unless StatisticIndex.find_by(es_type_key: 'account')
  StatisticIndex.create!({ id: 5, es_type_key: 'account', label_i18n_path: 'statistics.registrations', ca: false })
end
unless StatisticIndex.find_by(es_type_key: 'project')
  StatisticIndex.create!({ id: 6, es_type_key: 'project', label_i18n_path: 'statistics.projects', ca: false })
end
unless StatisticIndex.find_by(es_type_key: 'user')
  StatisticIndex.create!({ id: 7, es_type_key: 'user', label_i18n_path: 'statistics.users', table: false, ca: false })
end
Database::Sequence.update_id_seq(StatisticIndex.table_name)
StatisticIndex.create!({ es_type_key: 'space', label_i18n_path: 'statistics.spaces' }) unless StatisticIndex.find_by(es_type_key: 'space')
StatisticIndex.create!({ es_type_key: 'order', label_i18n_path: 'statistics.orders' }) unless StatisticIndex.find_by(es_type_key: 'order')

statistic_index_space = StatisticIndex.find_by(es_type_key: 'space')
statistic_index_order = StatisticIndex.find_by(es_type_key: 'order')

# statistic_fields
unless StatisticField.find_by(key: 'spaceDates', statistic_index_id: statistic_index_space.id)
  StatisticField.create!({ key: 'spaceDates', label_i18n_path: 'statistics.space_dates',
                           statistic_index_id: statistic_index_space.id, data_type: 'list' })
end
unless StatisticField.find_by(key: 'groupName', statistic_index_id: statistic_index_space.id)
  StatisticField.create!({ key: 'groupName', label_i18n_path: 'statistics.group', statistic_index_id: statistic_index_space.id, data_type: 'text' })
end
unless StatisticField.find_by(key: 'machineDates', statistic_index_id: 2)
  StatisticField.create!({ key: 'machineDates', label_i18n_path: 'statistics.machine_dates', statistic_index_id: 2, data_type: 'list' })
end
unless StatisticField.find_by(key: 'groupName', statistic_index_id: 2)
  StatisticField.create!({ key: 'groupName', label_i18n_path: 'statistics.group', statistic_index_id: 2, data_type: 'text' })
end
unless StatisticField.find_by(key: 'trainingId', statistic_index_id: 3)
  StatisticField.create!({ key: 'trainingId', label_i18n_path: 'statistics.training_id', statistic_index_id: 3, data_type: 'index' })
end
unless StatisticField.find_by(key: 'trainingDate', statistic_index_id: 3)
  StatisticField.create!({ key: 'trainingDate', label_i18n_path: 'statistics.training_date', statistic_index_id: 3, data_type: 'date' })
end
unless StatisticField.find_by(key: 'groupName', statistic_index_id: 3)
  StatisticField.create!({ key: 'groupName', label_i18n_path: 'statistics.group', statistic_index_id: 3, data_type: 'text' })
end
unless StatisticField.find_by(key: 'eventId', statistic_index_id: 4)
  StatisticField.create!({ key: 'eventId', label_i18n_path: 'statistics.event_id', statistic_index_id: 4, data_type: 'index' })
end
unless StatisticField.find_by(key: 'eventDate', statistic_index_id: 4)
  StatisticField.create!({ key: 'eventDate', label_i18n_path: 'statistics.event_date', statistic_index_id: 4, data_type: 'date' })
end
unless StatisticField.find_by(key: 'groupName', statistic_index_id: 4)
  StatisticField.create!({ key: 'groupName', label_i18n_path: 'statistics.group', statistic_index_id: 4, data_type: 'text' })
end
unless StatisticField.find_by(key: 'groupName', statistic_index_id: 5)
  StatisticField.create!({ key: 'groupName', label_i18n_path: 'statistics.group', statistic_index_id: 5, data_type: 'text' })
end
unless StatisticField.find_by(key: 'themes', statistic_index_id: 6)
  StatisticField.create!({ key: 'themes', label_i18n_path: 'statistics.themes', statistic_index_id: 6, data_type: 'list' })
end
unless StatisticField.find_by(key: 'components', statistic_index_id: 6)
  StatisticField.create!({ key: 'components', label_i18n_path: 'statistics.components', statistic_index_id: 6, data_type: 'list' })
end
unless StatisticField.find_by(key: 'machines', statistic_index_id: 6)
  StatisticField.create!({ key: 'machines', label_i18n_path: 'statistics.machines', statistic_index_id: 6, data_type: 'list' })
end
unless StatisticField.find_by(key: 'status', statistic_index_id: 6)
  StatisticField.create!({ key: 'status', label_i18n_path: 'statistics.project_status', statistic_index_id: 6, data_type: 'text' })
end
unless StatisticField.find_by(key: 'name', statistic_index_id: 6)
  StatisticField.create!({ key: 'name', label_i18n_path: 'statistics.project_name', statistic_index_id: 6, data_type: 'text' })
end
unless StatisticField.find_by(key: 'projectUserNames', statistic_index_id: 6)
  StatisticField.create!({ key: 'projectUserNames', label_i18n_path: 'statistics.project_user_names', statistic_index_id: 6, data_type: 'list' })
end
unless StatisticField.find_by(key: 'name', statistic_index_id: 4)
  StatisticField.create!({ key: 'name', label_i18n_path: 'statistics.event_name', statistic_index_id: 4, data_type: 'text' })
end
unless StatisticField.find_by(key: 'userId', statistic_index_id: 7)
  StatisticField.create!({ key: 'userId', label_i18n_path: 'statistics.user_id', statistic_index_id: 7, data_type: 'index' })
end
unless StatisticField.find_by(key: 'eventTheme', statistic_index_id: 4)
  StatisticField.create!({ key: 'eventTheme', label_i18n_path: 'statistics.event_theme', statistic_index_id: 4, data_type: 'text' })
end
unless StatisticField.find_by(key: 'ageRange', statistic_index_id: 4)
  StatisticField.create!({ key: 'ageRange', label_i18n_path: 'statistics.age_range', statistic_index_id: 4, data_type: 'text' })
end
unless StatisticField.find_by(key: 'groupName', statistic_index_id: 1)
  StatisticField.create!({ key: 'groupName', label_i18n_path: 'statistics.group', statistic_index_id: 1, data_type: 'text' })
end
unless StatisticField.find_by(key: 'groupName', statistic_index_id: statistic_index_order.id)
  StatisticField.create!({ key: 'groupName', label_i18n_path: 'statistics.group', statistic_index_id: statistic_index_order.id, data_type: 'text' })
end

# statistic_types
unless StatisticType.find_by(key: 'booking', statistic_index_id: 2)
  StatisticType.create!({ statistic_index_id: 2, key: 'booking', label_i18n_path: 'statistics.bookings', graph: true, simple: true })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: 2)
  StatisticType.create!({ statistic_index_id: 2, key: 'hour', label_i18n_path: 'statistics.hours_number', graph: true, simple: false })
end
unless StatisticType.find_by(key: 'booking', statistic_index_id: 3)
  StatisticType.create!({ statistic_index_id: 3, key: 'booking', label_i18n_path: 'statistics.bookings', graph: false, simple: true })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: 3)
  StatisticType.create!({ statistic_index_id: 3, key: 'hour', label_i18n_path: 'statistics.hours_number', graph: false, simple: false })
end
unless StatisticType.find_by(key: 'booking', statistic_index_id: 4)
  StatisticType.create!({ statistic_index_id: 4, key: 'booking', label_i18n_path: 'statistics.tickets_number', graph: false, simple: false })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: 4)
  StatisticType.create!({ statistic_index_id: 4, key: 'hour', label_i18n_path: 'statistics.hours_number', graph: false, simple: false })
end
unless StatisticType.find_by(key: 'member', statistic_index_id: 5)
  StatisticType.create!({ statistic_index_id: 5, key: 'member', label_i18n_path: 'statistics.users', graph: true, simple: true })
end
unless StatisticType.find_by(key: 'project', statistic_index_id: 6)
  StatisticType.create!({ statistic_index_id: 6, key: 'project', label_i18n_path: 'statistics.projects', graph: false, simple: true })
end
unless StatisticType.find_by(key: 'revenue', statistic_index_id: 7)
  StatisticType.create!({ statistic_index_id: 7, key: 'revenue', label_i18n_path: 'statistics.revenue', graph: false, simple: false })
end
unless StatisticType.find_by(key: 'booking', statistic_index_id: statistic_index_space.id)
  StatisticType.create!({ statistic_index_id: statistic_index_space.id, key: 'booking', label_i18n_path: 'statistics.bookings',
                          graph: true, simple: true })
end
unless StatisticType.find_by(key: 'hour', statistic_index_id: statistic_index_space.id)
  StatisticType.create!({ statistic_index_id: statistic_index_space.id, key: 'hour', label_i18n_path: 'statistics.hours_number',
                          graph: true, simple: false })
end
unless StatisticType.find_by(key: 'store', statistic_index_id: statistic_index_order.id)
  StatisticType.create!({ statistic_index_id: statistic_index_order.id, key: 'store', label_i18n_path: 'statistics.store',
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
  StatisticSubType.create!({ key: 'created', label_i18n_path: 'statistics.account_creation',
                             statistic_types: StatisticIndex.find_by(es_type_key: 'account').statistic_types })
end
unless StatisticSubType.find_by(key: 'published')
  StatisticSubType.create!({ key: 'published', label_i18n_path: 'statistics.project_publication',
                             statistic_types: StatisticIndex.find_by(es_type_key: 'project').statistic_types })
end
unless StatisticSubType.find_by(key: 'paid-processed')
  StatisticSubType.create!({ key: 'paid-processed', label_i18n_path: 'statistics.paid-rocessed',
                             statistic_types: statistic_index_order.statistic_types })
end
unless StatisticSubType.find_by(key: 'aborted')
  StatisticSubType.create!({ key: 'aborted', label_i18n_path: 'statistics.aborted', statistic_types: statistic_index_order.statistic_types })
end
Plan.find_each do |plan|
  type = plan.find_statistic_type
  subtype = StatisticSubType.create_with(label: plan.name).find_or_create_by(key: plan.slug)
  StatisticTypeSubType.find_or_create_by(statistic_type: type, statistic_sub_type: subtype)
end

statistic_index_machine = StatisticIndex.find_by(es_type_key: 'machine')
Machine.find_each do |machine|
  subtype = StatisticSubType.create_with(label: machine.name).find_or_create_by(key: machine.slug)
  statistic_index_machine.statistic_types.find_each do |type|
    StatisticTypeSubType.find_or_create_by(statistic_type: type, statistic_sub_type: subtype)
  end
end

statistic_index_training = StatisticIndex.find_by(es_type_key: 'training')
Training.find_each do |training|
  subtype = StatisticSubType.create_with(label: training.name).find_or_create_by(key: training.slug)
  statistic_index_training.statistic_types.find_each do |type|
    StatisticTypeSubType.find_or_create_by(statistic_type: type, statistic_sub_type: subtype)
  end
end

Space.find_each do |space|
  subtype = StatisticSubType.create_with(label: space.name).find_or_create_by(key: space.slug)
  statistic_index_space.statistic_types.find_each do |type|
    StatisticTypeSubType.find_or_create_by(statistic_type: type, statistic_sub_type: subtype)
  end
end

statistic_index_user = StatisticIndex.find_by(es_type_key: 'user')
Group.find_each do |group|
  subtype = StatisticSubType.create_with(label: group.name).find_or_create_by(key: group.slug)
  statistic_index_user.statistic_types.find_each do |type|
    StatisticTypeSubType.find_or_create_by(statistic_type: type, statistic_sub_type: subtype)
  end
end

statistic_index_event = StatisticIndex.find_by(es_type_key: 'event')
Category.find_each do |category|
  subtype = StatisticSubType.create_with(label: category.name).find_or_create_by(key: category.slug)
  statistic_index_event.statistic_types.find_each do |type|
    StatisticTypeSubType.find_or_create_by(statistic_type: type, statistic_sub_type: subtype)
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
