class InsertCustomAggregations < ActiveRecord::Migration
  def up
    # available reservations hours for machines
    machine = StatisticIndex.find_by_es_type_key('machine')
    machine_hours = StatisticType.find_by(key: 'hour', statistic_index_id: machine.id)

    available_hours = StatisticCustomAggregation.new({
      statistic_type_id: machine_hours.id,
      es_index: 'fablab',
      es_type: 'availabilities',
      field: 'available_hours',
      query: '{"size":0, "aggregations":{"%{aggs_name}":{"sum":{"field":"hours_duration"}}}, "query":{"bool":{"must":[{"range":{"start_at":{"gte":"%{start_date}", "lte":"%{end_date}"}}}, {"match":{"available_type":"machines"}}]}}}'
    })
    available_hours.save!

    # available training tickets
    training = StatisticIndex.find_by_es_type_key('training')
    training_bookings = StatisticType.find_by(key: 'booking', statistic_index_id: training.id)

    available_tickets = StatisticCustomAggregation.new({
      statistic_type_id: training_bookings.id,
      es_index: 'fablab',
      es_type: 'availabilities',
      field: 'available_tickets',
      query: '{"size":0, "aggregations":{"%{aggs_name}":{"sum":{"field":"nb_total_places"}}}, "query":{"bool":{"must":[{"range":{"start_at":{"gte":"%{start_date}", "lte":"%{end_date}"}}}, {"match":{"available_type":"training"}}]}}}'
    })
    available_tickets.save!
  end

  def down

    machine = StatisticIndex.find_by_es_type_key('machine')
    machine_hours = StatisticType.find_by(key: 'hour', statistic_index_id: machine.id)

    StatisticCustomAggregation.where(field: 'available_hours', statistic_type_id: machine_hours.id).first.destroy!

    training = StatisticIndex.find_by_es_type_key('training')
    training_bookings = StatisticType.find_by(key: 'booking', statistic_index_id: training.id)

    StatisticCustomAggregation.where(field: 'available_tickets', statistic_type_id: training_bookings.id).first.destroy!
  end
end
