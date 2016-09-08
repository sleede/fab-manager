
# we protect some fields are they are designed to be managed by the system and must not be updated externally

json.user User.column_names - %w(id encrypted_password reset_password_token reset_password_sent_at remember_created_at
sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip confirmation_token confirmed_at
confirmation_sent_at unconfirmed_email failed_attempts unlock_token locked_at created_at updated_at stp_customer_id slug
provider auth_token merged_at)

json.profile Profile.column_names - %w(id user_id created_at updated_at) + %w(avatar address organization_name organization_address)