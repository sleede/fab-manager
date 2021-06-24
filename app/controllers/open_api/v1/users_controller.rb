# frozen_string_literal: true

# public API controller for users
class OpenAPI::V1::UsersController < OpenAPI::V1::BaseController
  extend OpenAPI::ApiDoc
  include Rails::Pagination
  expose_doc

  def index
    @users = User.order(created_at: :desc).includes(:group, :profile)

    if params[:email].present?
      email_param = params[:email].is_a?(String) ? params[:email].downcase : params[:email].map(&:downcase)
      @users = @users.where(email: email_param)
    end
    @users = @users.where(id: params[:user_id]) if params[:user_id].present?

    return unless params[:page].present?

    @users = @users.page(params[:page]).per(per_page)
    paginate @users, per_page: per_page
  end

  private

  def per_page
    params[:per_page] || 20
  end
end
