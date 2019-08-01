# frozen_string_literal: true

# API Controller for resources of type Export
# Export are used to download data tables in offline files
class API::ExportsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_export, only: [:download]

  def download
    authorize @export
    mime_type = if @export.extension == 'xlsx'
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                elsif @export.extension == 'csv'
                  'text/csv'
                else
                  'application/octet-stream'
                end

    if FileTest.exist?(@export.file)
      send_file File.join(Rails.root, @export.file),
                type: mime_type,
                disposition: 'attachment'
    else
      render text: I18n.t('errors.messages.export_not_found'), status: :not_found
    end
  end

  def status
    authorize Export

    exports = Export.where(
      category: params[:category],
      export_type: params[:type],
      query: params[:query],
      key: params[:key],
      extension: params[:extension]
    )
    export = retrieve_last_export(exports, params[:category], params[:type])

    if export.nil? || !FileTest.exist?(export.file)
      render json: { exists: false, id: nil }, status: :ok
    else
      render json: { exists: true, id: export.id }, status: :ok
    end
  end

  private

  def retrieve_last_export(export, category, type)
    case category
    when 'users'
      case type
      when 'subscriptions'
        export = export.where('created_at > ?', Subscription.maximum('updated_at'))
      when 'reservations'
        export = export.where('created_at > ?', Reservation.maximum('updated_at'))
      when 'members'
        export = export.where('created_at > ?', User.with_role(:member).maximum('updated_at'))
      else
        raise ArgumentError, "Unknown export users/#{type}"
      end
    when 'availabilities'
      case type
      when 'index'
        export = export.where('created_at > ?', [Availability.maximum('updated_at'), Reservation.maximum('updated_at')].max)
      else
        raise ArgumentError, "Unknown type availabilities/#{type}"
      end
    when 'accounting'
      case type
      when 'accounting-software'
        export = export.where('created_at > ?', Invoice.maximum('updated_at'))
      else
        raise ArgumentError, "Unknown type accounting/#{type}"
      end
    else
      raise ArgumentError, "Unknown category #{category}"
    end
    export.last
  end

  def set_export
    @export = Export.find(params[:id])
  end
end
