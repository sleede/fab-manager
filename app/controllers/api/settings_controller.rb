# frozen_string_literal: true

# API Controller for resources of type Setting
class API::SettingsController < API::ApiController
  before_action :authenticate_user!, only: %i[update bulk_update reset]

  def index
    @settings = policy_scope(Setting.where(name: names_as_string_to_array))
  end

  def update
    authorize Setting
    @setting = Setting.find_or_initialize_by(name: params[:name])
    render status: :not_modified and return if setting_params[:value] == @setting.value
    render status: :locked, json: { error: I18n.t('settings.locked_setting') } and return unless SettingService.before_update(@setting)

    if @setting.save && @setting.history_values.create(value: setting_params[:value], invoicing_profile: current_user.invoicing_profile)
      SettingService.after_update(@setting)
      render status: :ok
    else
      render json: @setting.errors.full_messages, status: :unprocessable_entity
    end
  end

  def bulk_update
    authorize Setting

    @settings = []
    may_transaction(params[:transactional]) do
      params[:settings].each do |setting|
        next if !setting[:name] || !setting[:value]

        db_setting = Setting.find_or_initialize_by(name: setting[:name])
        if !SettingService.before_update(db_setting)
          db_setting.errors[:-] << I18n.t("settings.#{setting[:name]}") + ': ' + I18n.t('settings.locked_setting')
        elsif db_setting.save
          db_setting.history_values.create(value: setting[:value], invoicing_profile: current_user.invoicing_profile)
          SettingService.after_update(db_setting)
        end

        @settings.push db_setting
        may_rollback(params[:transactional]) if db_setting.errors.keys.count.positive?
      end
    end
  end

  def show
    authorize SettingContext.new(params[:name])

    @setting = Setting.find_or_create_by(name: params[:name])
    @show_history = params[:history] == 'true' && current_user.admin?
  end

  def test_present
    authorize SettingContext.new(params[:name])

    @setting = Setting.get(params[:name])
  end

  def reset
    authorize Setting

    setting = Setting.find_or_create_by(name: params[:name])
    render status: :locked, json: { error: 'locked setting' } and return unless SettingService.before_update(setting)

    first_val = setting.history_values.order(created_at: :asc).limit(1).first
    new_val = HistoryValue.create!(
      setting_id: setting.id,
      value: first_val.value,
      invoicing_profile_id: current_user.invoicing_profile.id
    )
    SettingService.after_update(setting)
    render json: new_val, status: :ok
  end

  private

  def setting_params
    params.require(:setting).permit(:value)
  end

  def names_as_string_to_array
    params[:names][1..-2].split(',').map(&:strip).map { |param| param[1..-2] }.map(&:strip)
  end

  # run the given block in a transaction if `should` is true. Just run it normally otherwise
  def may_transaction(should)
    if should == 'true'
      ActiveRecord::Base.transaction do
        yield
      end
    else
      yield
    end
  end

  # rollback the current DB transaction if `should` is true
  def may_rollback(should)
    raise ActiveRecord::Rollback if should == 'true'
  end
end
