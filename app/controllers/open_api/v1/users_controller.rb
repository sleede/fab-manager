class OpenAPI::V1::UsersController < OpenAPI::V1::BaseController
  def index
    @users = User.order(created_at: :desc).includes(:group, :profile)

    if params[:email].present?
      @users = @users.where(email: params[:email].downcase)
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
