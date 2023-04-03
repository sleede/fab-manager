# frozen_string_literal: true

# public API controller for user's trainings
class OpenAPI::V1::UserTrainingsController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  expose_doc

  def index
    @user_trainings = StatisticProfileTraining.includes(statistic_profile: :user)
                                              .includes(:training)
                                              .references(:statistic_profiles)
                                              .order(created_at: :desc)

    @user_trainings = @user_trainings.where(statistic_profiles: { user_id: may_array(params[:user_id]) }) if params[:user_id].present?
    @user_trainings = @user_trainings.where(training_id: may_array(params[:training_id])) if params[:training_id].present?

    return if params[:page].blank?

    @user_trainings = @user_trainings.page(params[:page]).per(per_page)
    paginate @user_trainings, per_page: per_page
  end

  private

  def per_page
    params[:per_page] || 20
  end
end
