# frozen_string_literal: true

# Devise controller to handle validation of email addresses
class ConfirmationsController < Devise::ConfirmationsController
  
  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    end
  end

  # The path used after confirmation.
  def after_confirmation_path_for(_resource_name, resource)
    signed_in_root_path(resource)
  end
end
