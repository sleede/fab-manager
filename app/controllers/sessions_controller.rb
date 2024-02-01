# frozen_string_literal: true

# Devise controller for handling client sessions
class SessionsController < Devise::SessionsController
  def new
    active_provider = Rails.configuration.auth_provider
    if active_provider.providable_type == 'DatabaseProvider'
      super
    else
      redirect_post "/users/auth/#{active_provider.strategy_name}"
    end
  end

  # FIXME, Method DELETE is not allowed by Access-Control-Allow-Methods in preflight response.
  # def destroy
  #   active_provider = Rails.configuration.auth_provider
  #   if active_provider.providable_type == 'OpenIdConnectProvider'
  #     redirect_to "/users/auth/#{active_provider.strategy_name}/logout"
  #   else
  #     super
  #   end
  # end
end
