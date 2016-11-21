class API::ExportsController < API::ApiController
  before_action :authenticate_user!
  before_action :set_export, only: [:download]

  def download
    authorize @export

    if FileTest.exist?(@export.file)
      send_file File.join(Rails.root, @export.file), :type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :disposition => 'attachment'
    else
      render text: I18n.t('errors.messages.export_not_found'), status: :not_found
    end
  end

  def status
    authorize Export

    export = Export.where({category: params[:category], export_type: params[:type], query: params[:query], key: params[:key]})

    if params[:category] === 'users'
      case params[:type]
        when 'subscriptions'
          export = export.where('created_at > ?', Subscription.maximum('updated_at'))
        when 'reservations'
          export = export.where('created_at > ?', Reservation.maximum('updated_at'))
        when 'members'
          export = export.where('created_at > ?', User.with_role(:member).maximum('updated_at'))
        else
          raise ArgumentError, "Unknown type #{params[:type]}"
      end
    end
    export = export.last

    if export.nil? || !FileTest.exist?(export.file)
      render json: {exists: false, id: nil}, status: :ok
    else
      render json: {exists: true, id: export.id}, status: :ok
    end
  end

  private
  def set_export
    @export = Export.find(params[:id])
  end
end