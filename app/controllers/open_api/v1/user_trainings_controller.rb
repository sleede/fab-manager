class OpenAPI::V1::UserTrainingsController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc
  
  def index
    @user_trainings = UserTraining.order(created_at: :desc)

    if params[:user_id].present?
      @user_trainings = @user_trainings.where(user_id: params[:user_id])
    else
      @user_trainings = @user_trainings.includes(user: :profile)
    end

    if params[:training_id].present?
      @user_trainings = @user_trainings.where(training_id: params[:training_id])
    else
      @user_trainings = @user_trainings.includes(:training)
    end

    if params[:page].present?
      @user_trainings = @user_trainings.page(params[:page]).per(per_page)
      paginate @user_trainings, per_page: per_page
    end
  end

  private
    def per_page
      params[:per_page] || 20
    end
end
