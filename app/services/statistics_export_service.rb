require 'abstract_controller'
require 'action_controller'
require 'action_view'
require 'active_record'

# require any helpers
require './app/helpers/application_helper'

class StatisticsExportService

  def export_global(export)

    # query all stats with range arguments
    query = MultiJson.load(export.query)

    @results = Elasticsearch::Model.client.search({index: 'stats', scroll: '30s', body: query})
    scroll_id = @results['_scroll_id']
    while @results['hits']['hits'].size != @results['hits']['total']
      scroll_res = Elasticsearch::Model.client.scroll(scroll: '30s', scroll_id: scroll_id)
      @results['hits']['hits'].concat(scroll_res['hits']['hits'])
      scroll_id = scroll_res['_scroll_id']
    end

    ids = @results['hits']['hits'].map { |u| u['_source']['userId'] }
    @users = User.includes(:profile).where(:id => ids)

    @indices = StatisticIndex.all.includes(:statistic_fields, :statistic_types => [:statistic_sub_types])

    ActionController::Base.prepend_view_path './app/views/'
    # place data in view_assigns
    view_assigns = {results: @results, users: @users, indices: @indices}
    av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
    av.class_eval do
      # include any needed helpers (for the view)
      include ApplicationHelper
    end

    content = av.render template: 'exports/statistics_global.xlsx.axlsx'
    # write content to file
    File.open(export.file,"w+b") {|f| f.puts content }
  end

  %w(account event machine project subscription training).each do |path|
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

        ActionController::Base.prepend_view_path './app/views/'
        # place data in view_assigns
        view_assigns = {results: @results, users: @users, index: @index, type: @type, subtypes: @subtypes, fields: @fields}
        av = ActionView::Base.new(ActionController::Base.view_paths, view_assigns)
        av.class_eval do
          # include any needed helpers (for the view)
          include ApplicationHelper
        end

        content = av.render template: 'exports/statistics_current.xlsx.axlsx'
        # write content to file
        File.open(export.file,"w+b") {|f| f.puts content }
      end
    }
  end

end