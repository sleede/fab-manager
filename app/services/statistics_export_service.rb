# frozen_string_literal: true

require 'abstract_controller'
require 'action_controller'
require 'action_view'
require 'active_record'

# require any helpers
require './app/helpers/excel_helper'

# Export statistics (from elasticsearch) to an excel file
class StatisticsExportService
  def export_global(export)
    # query all stats with range arguments
    query = MultiJson.load(export.query)

    @results = Elasticsearch::Model.client.search(index: 'stats', scroll: '30s', body: query)
    scroll_id = @results['_scroll_id']
    while @results['hits']['hits'].size != @results['hits']['total']
      scroll_res = Elasticsearch::Model.client.scroll(scroll: '30s', scroll_id: scroll_id)
      @results['hits']['hits'].concat(scroll_res['hits']['hits'])
      scroll_id = scroll_res['_scroll_id']
    end

    ids = @results['hits']['hits'].map { |u| u['_source']['userId'] }
    @users = User.includes(:profile).where(id: ids)

    @indices = StatisticIndex.all.includes(:statistic_fields, statistic_types: [:statistic_sub_types])

    content = ApplicationController.render(
      template: 'exports/statistics_global',
      locals: { results: @results, users: @users, indices: @indices },
      handlers: [:axlsx],
      formats: [:xlsx]
    )
    # write content to file
    File.binwrite(export.file, content)
  end

  # rubocop:disable Style/DocumentDynamicEvalDefinition
  %w[account event machine project subscription training space order].each do |path|
    class_eval %{
      def export_#{path}(export)

        query = MultiJson.load(export.query)
        type_key = export.key

        @results = Elasticsearch::Model.client.search({index: 'stats', type: '#{path}', scroll: '30s', body: query})
        scroll_id = @results['_scroll_id']
        while @results['hits']['hits'].size != @results['hits']['total']
          scroll_res = Elasticsearch::Model.client.scroll(scroll: '30s', scroll_id: scroll_id)
          @results['hits']['hits'].concat(scroll_res['hits']['hits'])
          scroll_id = scroll_res['_scroll_id']
        end

        ids = @results['hits']['hits'].map { |u| u['_source']['userId'] }
        @users = User.includes(:profile).where(:id => ids)

        @index = StatisticIndex.find_by(es_type_key: '#{path}')
        @type = StatisticType.find_by(key: type_key, statistic_index_id: @index.id)
        @subtypes = @type.statistic_sub_types
        @fields = @index.statistic_fields

        content = ApplicationController.render(
          template: 'exports/statistics_current',
          locals: { results: @results, users: @users, index: @index, type: @type, subtypes: @subtypes, fields: @fields },
          handlers: [:axlsx],
          formats: [:xlsx]
        )
        # write content to file
        File.binwrite(export.file, content)
      end
    }, __FILE__, __LINE__ - 31
  end
  # rubocop:enable Style/DocumentDynamicEvalDefinition
end
