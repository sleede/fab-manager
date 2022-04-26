# frozen_string_literal: true

# Devise controller to handle validation of email addresses
class ConfirmationsController < Devise::ConfirmationsController
  # The path used after confirmation.
  def after_confirmation_path_for(_resource_name, resource)
    signed_in_root_path(resource)
  end
end
