# frozen_string_literal: true

# API Controller for various statistical resources (gateway to elasticsearch DB)
class API::StatisticsController < API::APIController
  before_action :authenticate_user!

  rescue_from SearchIndex::IncompleteRead, SearchIndex::Connection::Unavailable, Elastic::Transport::Transport::Error, Faraday::Error,
              with: :unavailable_search
  rescue_from SearchIndex::UnsupportedQuery, JSON::ParserError, MultiJson::ParseError, with: :invalid_search
  rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :expired_search
  rescue_from Elastic::Transport::Transport::Errors::BadRequest, with: :invalid_search
  rescue_from Elastic::Transport::Transport::Errors::NotFound, with: :expired_search

  def index
    authorize :statistic, :index?
    @statistics = StatisticIndex.all
  end

  %w[account event machine project subscription training user space order].each do |path|
    class_eval %{
      def #{path}                                                       # def account
        authorize :statistic, :#{path}?                                 #   authorize :statistic, :account
        result = Statistics::QueryService.query('#{path}', request)     #   result = Statistics::QueryService.query('account', request)
        render json: browser_result(result)                             #   render json: browser_result(result)
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
    }, __FILE__, __LINE__ - 24
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

    results = SearchIndex.next_page(cursor: verified_cursor, keep_alive: params[:scroll] || '30s').legacy_response
    render json: browser_result(results)
  end

  def clear_scroll
    authorize :statistic, :scroll?
    SearchIndex.close_cursor(cursor: verified_cursor)
    head :no_content
  end

  private

  def browser_result(result)
    return result unless result['_scroll_id']

    result.merge('_scroll_id' => cursor_verifier.generate(result['_scroll_id'], purpose: 'statistics', expires_in: 5.minutes))
  end

  def verified_cursor
    cursor_verifier.verified(params[:scrollId], purpose: 'statistics') || raise(ActiveSupport::MessageVerifier::InvalidSignature)
  end

  def cursor_verifier
    Rails.application.message_verifier('statistics-scroll')
  end

  def invalid_search
    render json: { error: 'invalid_statistics_query' }, status: :unprocessable_entity
  end

  def expired_search
    render json: { error: 'expired_statistics_search' }, status: :gone
  end

  def unavailable_search
    render json: { error: 'statistics_unavailable' }, status: :service_unavailable
  end
end
