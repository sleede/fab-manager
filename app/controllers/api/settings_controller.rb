class API::SettingsController < API::ApiController
  before_action :authenticate_user!, only: :update

  def index
    @settings = Setting.where(name: names_as_string_to_array)
  end

  def update
    authorize Setting
    @setting = Setting.find_or_initialize_by(name: params[:name])
    if @setting.update(setting_params)
      render status: :ok
    else
      render json: @setting.errors.full_messages, status: :unprocessable_entity
    end
  end

  def show
    @setting = Setting.find_or_create_by(name: params[:name])
  end

  private
    def setting_params
      params.require(:setting).permit(:value)
    end

    def names_as_string_to_array
      params[:names][1..-2].split(',').map(&:strip).map { |param| param[1..-2] }.map(&:strip)
    end
end
