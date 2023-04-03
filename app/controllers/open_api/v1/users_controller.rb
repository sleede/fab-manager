# frozen_string_literal: true

# public API controller for users
class OpenAPI::V1::UsersController < OpenAPI::V1::BaseController
  extend OpenAPI::APIDoc
  include Rails::Pagination
  expose_doc

  def index
    @users = User.order(created_at: :desc).includes(:group, :profile, :invoicing_profile)

    if params[:email].present?
      email_param = params[:email].is_a?(String) ? params[:email].downcase : params[:email].map(&:downcase)
      @users = @users.where(email: email_param)
    end
    @users = @users.where(id: may_array(params[:user_id])) if params[:user_id].present?
    @users = @users.where('created_at >= ?', Time.zone.parse(params[:created_after])) if params[:created_after].present?

    return if params[:page].blank?

    @users = @users.page(page).per(per_page)
    paginate @users, per_page: per_page
  end

  private

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 20
  end
end
