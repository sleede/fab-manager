# frozen_string_literal: true

# Query the elasticsearch database of statistics and format the result
class Statistics::QueryService
  class << self
    def query(statistic_index, request)
      # remove additional parameters
      statistic_type = request.query_parameters.delete('stat-type')
      custom_query = request.query_parameters.delete('custom-query')
      start_date = request.query_parameters.delete('start-date')
      end_date = request.query_parameters.delete('end-date')

      # run main query in elasticSearch
      query = MultiJson.load(request.body.read)
      model = "Stats::#{statistic_index}".constantize
      results = model.search(query, request.query_parameters.symbolize_keys).response

      # run additional custom aggregations, if any
      CustomAggregationService.new.call(statistic_index, statistic_type, start_date, end_date, custom_query, results)

      results
    end

    def export(statistic_index, params)
      export = ExportService.last_export("statistics/#{statistic_index}")
      if export.nil? || !FileTest.exist?(export.file)
        Export.new(category: 'statistics',
                   export_type: statistic_index,
                   user: current_user,
                   query: params[:body],
                   key: params[:type_key])
      else
        File.root.join(export.file)
      end
    end
  end
end
