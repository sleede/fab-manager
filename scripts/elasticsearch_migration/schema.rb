# frozen_string_literal: true

# Run with rails runner against the SQL source while all application producers are stopped.
# This exports schemas/queries only; it never rebuilds statistics or writes Elasticsearch.
families = SearchIndex::FAMILIES.to_h do |family|
  source_index = family == 'availabilities' ? 'fablab' : 'stats'
  fields = family == 'availabilities' ? %w[hours_duration bookable_hours] : %w[stat ca]
  aggs = fields.index_with { |field| { sum: { field: field } } }
  aggs.merge!(dates_min: { min: { field: 'date' } }, dates_max: { max: { field: 'date' } },
              months: { date_histogram: { field: 'date', interval: 'month', time_zone: 'America/Toronto' } })
  aggs[:subtypes] = { terms: { field: 'subType', size: 1000, order: { _term: 'asc' } } } unless family == 'availabilities'
  query = { size: 0, aggs: aggs }
  [family, { source_index: source_index, source_type: family, target: SearchIndex::Schema.physical(family),
             alias: SearchIndex.target(family).fetch(:index), definition: SearchIndex::Schema.definition(family),
             probes: [{ name: 'business', source: query, target: SearchIndex::Query.build(query) }] }]
end
customs = StatisticCustomAggregation.order(:id).map do |custom|
  { id: custom.id, es_index: custom.es_index, es_type: custom.es_type, field: custom.field, query: custom.query }
end
customs.each do |custom|
  family = SearchIndex.family_for(index: custom[:es_index], type: custom[:es_type])
  source = JSON.parse(sprintf(custom[:query], aggs_name: custom[:field], start_date: '1900-01-01', end_date: '2100-01-01'))
  families.fetch(family)[:probes] << { name: "sql-custom-#{custom[:id]}", source: source, target: SearchIndex::Query.build(source) }
end
File.write(ENV.fetch('ES_MIGRATION_SCHEMA_OUTPUT'), JSON.pretty_generate({ format: 1, families: families, sql_custom_aggregations: customs }))
