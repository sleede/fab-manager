json.array!(@statistics) do |s|
  json.extract! s, :id, :es_type_key, :label, :table, :ca
  json.additional_fields s.statistic_fields do |f|
    json.extract! f, :key, :label, :data_type
  end
  json.types s.statistic_types do |t|
    json.extract! t, :id, :key, :label, :graph, :simple
    json.custom_aggregations t.statistic_custom_aggregations do |c|
      json.extract! c, :id, :field
    end
    json.subtypes t.statistic_sub_types do |st|
      json.extract! st, :id, :key, :label
    end
  end
  json.graph do
    json.chart_type s.statistic_graph.chart_type
    json.limit s.statistic_graph.limit
  end if s.statistic_graph
end