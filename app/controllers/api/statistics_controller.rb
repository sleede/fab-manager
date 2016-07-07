class API::StatisticsController < API::ApiController
  before_action :authenticate_user!

  def index
    authorize :statistic, :index?
    @statistics = StatisticIndex.all
  end

  %w(account event machine project subscription training user).each do |path|
    class_eval %{
      def #{path}
        authorize :statistic, :#{path}?
        query = MultiJson.load(request.body.read)
        results = Stats::#{path.classify}.search(query, request.query_parameters.symbolize_keys).response
        render json: results
      end

      def export_#{path}
        authorize :statistic, :#{path}?
        query = MultiJson.load(params[:body])
        @results = Elasticsearch::Model.client.search({index: 'stats', type: '#{path}', scroll: '30s', body: query})
        scroll_id = @results['_scroll_id']
        while @results['hits']['hits'].size != @results['hits']['total']
          scroll_res = Elasticsearch::Model.client.scroll(scroll: '30s', scroll_id: scroll_id)
          @results['hits']['hits'].concat(scroll_res['hits']['hits'])
          scroll_id = scroll_res['_scroll_id']
        end
        ids = @results['hits']['hits'].map { |u| u['_source']['userId'] }
        @users = User.includes(:profile).where(:id => ids)
        type_key = query['query']['bool']['must'][0]['term']['type'].to_s
        @subtypes = StatisticType.find_by(key: type_key, statistic_index_id: StatisticIndex.find_by(es_type_key: '#{path}').id).statistic_sub_types
        render xlsx: 'export_#{path}.xlsx', filename: "#{path}.xlsx"
      end
    }
  end

  def export_global
    # query all stats with range arguments
    Elasticsearch::Model.client.search
    render xls: []
  end

  def scroll
    authorize :statistic, :scroll?

    results = Elasticsearch::Model.client.scroll scroll: params[:scroll], scroll_id: params[:scrollId]
    render json: results
  end

end
