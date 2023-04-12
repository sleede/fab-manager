# frozen_string_literal: true

# API Controller for resources of type Setting
class API::SettingsController < API::APIController
  before_action :authenticate_user!, only: %i[update bulk_update reset]

  def index
    @settings = policy_scope(Setting.where(name: names_as_string_to_array))
  end

  def update
    authorize Setting
    @setting = Setting.find_or_initialize_by(name: params[:name])
    render status: :not_modified and return if setting_params[:value] == @setting.value
    render status: :locked, json: { error: I18n.t('settings.locked_setting') } and return unless SettingService.update_allowed?(@setting)

    error = SettingService.check_before_update({ name: params[:name], value: setting_params[:value] })
    render status: :unprocessable_entity, json: { error: error } and return if error

    if SettingService.save_and_update(@setting, setting_params[:value], current_user)
      SettingService.run_after_update([@setting])
      render status: :ok
    else
      render json: @setting.errors.full_messages, status: :unprocessable_entity
    end
  end

  def bulk_update
    authorize Setting

    @settings = []
    updated_settings = []
    may_transaction params[:transactional] do
      params[:settings].each do |setting|
        next if !setting[:name] || !setting[:value] || setting[:value].blank?

        db_setting = Setting.find_or_initialize_by(name: setting[:name])
        if SettingService.update_allowed?(db_setting)
          error = SettingService.check_before_update(setting)
          if error
            db_setting.errors.add(:-, "#{I18n.t("settings.#{setting[:name]}")}: #{error}")
          elsif db_setting.value != setting[:value] && SettingService.save_and_update(db_setting, setting[:value], current_user)
            updated_settings.push(db_setting)
          end
        else
          db_setting.errors.add(:-, "#{I18n.t("settings.#{setting[:name]}")}: #{I18n.t('settings.locked_setting')}")
        end

        @settings.push db_setting
        may_rollback(params[:transactional]) if db_setting.errors.attribute_names.count.positive?
      end
    end
    SettingService.run_after_update(updated_settings)
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
    render status: :locked, json: { error: 'locked setting' } and return unless SettingService.update_allowed?(setting)

    first_val = setting.history_values.order(created_at: :asc).limit(1).first
    new_val = HistoryValue.create!(
      setting_id: setting.id,
      value: first_val&.value,
      invoicing_profile_id: current_user.invoicing_profile.id
    )
    SettingService.run_after_update([setting])
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
  def may_transaction(should, &)
    if should == 'true'
      ActiveRecord::Base.transaction(&)
    else
      yield
    end
  end

  # rollback the current DB transaction if `should` is true
  def may_rollback(should)
    raise ActiveRecord::Rollback if should == 'true'
  end
end
