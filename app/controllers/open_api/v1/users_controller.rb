class OpenAPI::V1::UsersController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  expose_doc

  def index
    @users = User.order(created_at: :desc).includes(:group, :profile)

    if params[:email].present?
      email_param = params[:email].is_a?(String) ? params[:email].downcase : params[:email].map(&:downcase)
      @users = @users.where(email: email_param)
    end

    if params[:user_id].present?
      @users = @users.where(id: params[:user_id])
    end

    if params[:page].present?
      @users = @users.page(params[:page]).per(per_page)
      paginate @users, per_page: per_page
    end
  end

  private
    def per_page
      params[:per_page] || 20
    end
end
