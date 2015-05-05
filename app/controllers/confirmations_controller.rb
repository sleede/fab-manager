class ConfirmationsController < Devise::ConfirmationsController
  # The path used after confirmation.
  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      signed_in_root_path(resource)
    else
      signed_in_root_path(resource)
    end
  end
end
