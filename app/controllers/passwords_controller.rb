# frozen_string_literal: true

# Devise controller used for the "forgotten password" feature
class PasswordsController < Devise::PasswordsController
  # POST /users/password.json
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      head 404
    end
  end
end
