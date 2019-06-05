# frozen_string_literal: true

# Devise controller for handling client sessions
class SessionsController < Devise::SessionsController

  def new
    active_provider = AuthProvider.active
    if active_provider.providable_type != DatabaseProvider.name
      redirect_to "/users/auth/#{active_provider.strategy_name}"
    else
      super
    end
  end
end
