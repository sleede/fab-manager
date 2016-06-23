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
    }
  end

  def scroll
    authorize :statistic, :scroll?

    results = Elasticsearch::Model.client.scroll scroll: params[:scroll], scroll_id: params[:scrollId]
    render json: results
  end

end
