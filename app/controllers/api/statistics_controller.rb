# frozen_string_literal: true

# API Controller for various statistical resources (gateway to elasticsearch DB)
class API::StatisticsController < API::APIController
  before_action :authenticate_user!

  def index
    authorize :statistic, :index?
    @statistics = StatisticIndex.all
  end

  %w[account event machine project subscription training user space order].each do |path|
    class_eval %{
      def #{path}                                                       # def account
        authorize :statistic, :#{path}?                                 #   authorize :statistic, :account
        render json: Statistics::QueryService.query('#{path}', request) #   render json: Statistics::QueryService.query('account', request)
      end                                                               # end

      def export_#{path}                                                # def export_account
        authorize :statistic, :export_#{path}?                          # authorize :statistic, :export_account?

        @export = Statistics::QueryService.export('#{path}', params,    # @export = Statistics::QueryService.export('account', params,
                                                  current_user)
        if @export.is_a?(Export)
          if @export.save
            render json: { export_id: @export.id }, status: :ok
          else
            render json: @export.errors, status: :unprocessable_entity
          end
        else
          send_file @export,
                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                    disposition: 'attachment'
        end
      end
    }, __FILE__, __LINE__ - 23
  end

  def export_global
    authorize :statistic, :export_global?

    @export = Statistics::QueryService.export('global', params, current_user)
    if @export.is_a?(Export)
      if @export.save
        render json: { export_id: @export.id }, status: :ok
      else
        render json: @export.errors, status: :unprocessable_entity
      end
    else
      send_file @export,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    end
  end

  def scroll
    authorize :statistic, :scroll?

    results = Elasticsearch::Model.client.scroll scroll: params[:scroll], scroll_id: params[:scrollId]
    render json: results
  end
end
