require 'json'

class CustomAggregationService

  ##
  # Run any additional custom aggregations related to the given statistic type, if any
  ##
  def call(statistic_index, statistic_type, start_date, end_date, custom_query, results)
    if statistic_type and start_date and end_date
      stat_index = StatisticIndex.find_by(es_type_key: statistic_index)
      stat_type = StatisticType.find_by(statistic_index_id: stat_index.id, key: statistic_type)
      client = Elasticsearch::Model.client
      stat_type.statistic_custom_aggregations.each do |custom|

        query = sprintf(custom.query, {aggs_name: custom.field, start_date: start_date, end_date: end_date})

        if custom_query and !custom_query.empty?
          # Here, a custom query was provided with the original request (eg: filter by subtype)
          # so we try to apply this custom filter to the current custom aggregation.
          #
          # The requested model mapping (ie. found in StatisticCustomAggregation.es_index > es_type) must have defined
          # these fields in the indexed json, otherwise the returned value will probably not be what is expected.
          #
          # As an implementation exemple, you can take a look at Availability (indexed as fablab/availabilities)
          # and witch will run custom filters on the fields 'date' and 'subType'. Other custom filters will return 0
          # as they are not relevant with this kind of custom aggregation.
          query = JSON.parse(query)
          custom_query = JSON.parse(custom_query)

          exclude = custom_query.delete('exclude')
          if exclude
            query['query']['bool']['must_not'] = [{ term: custom_query['match'] }]
          else
            query['query']['bool']['must'].push(custom_query)
          end
          query = query.to_json
        end

        c_res = client.search(index: custom.es_index, type: custom.es_type, body: query)
        results['aggregations'][custom.field] = c_res['aggregations'][custom.field]
      end
    end
    results
  end
end