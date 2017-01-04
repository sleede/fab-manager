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

        # remove additional parameters
        statistic_type = request.query_parameters.delete('stat-type')
        custom_query = request.query_parameters.delete('custom-query')
        start_date = request.query_parameters.delete('start-date')
        end_date = request.query_parameters.delete('end-date')

        # run main query in elasticSearch
        query = MultiJson.load(request.body.read)
        results = Stats::#{path.classify}.search(query, request.query_parameters.symbolize_keys).response

        # run additional custom aggregations, if any
        CustomAggregationService.new.("#{path}", statistic_type, start_date, end_date, custom_query, results)

        # return result
        render json: results
      end

      def export_#{path}
        authorize :statistic, :export_#{path}?

        export = Export.where({category:'statistics', export_type: '#{path}', query: params[:body], key: params[:type_key]}).last
        if export.nil? || !FileTest.exist?(export.file)
          @export = Export.new({category:'statistics', export_type: '#{path}', user: current_user, query: params[:body], key: params[:type_key]})
          if @export.save
            render json: {export_id: @export.id}, status: :ok
          else
            render json: @export.errors, status: :unprocessable_entity
          end
        else
          send_file File.join(Rails.root, export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
        end
      end
    }
  end

  def export_global
    authorize :statistic, :export_global?

    export = Export.where({category:'statistics', export_type: 'global', query: params[:body]}).last
    if export.nil? || !FileTest.exist?(export.file)
      @export = Export.new({category:'statistics', export_type: 'global', user: current_user, query: params[:body]})
      if @export.save
        render json: {export_id: @export.id}, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file File.join(Rails.root, export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
    end
  end

  def scroll
    authorize :statistic, :scroll?

    results = Elasticsearch::Model.client.scroll scroll: params[:scroll], scroll_id: params[:scrollId]
    render json: results
  end

end
