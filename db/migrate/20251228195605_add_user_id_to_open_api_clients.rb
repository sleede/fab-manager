# frozen_string_literal: true

# Add open_api token relation with user
class AddUserIdToOpenAPIClients < ActiveRecord::Migration[7.0]
  def up
    return unless table_exists?(:open_api_clients)
    return if column_exists?(:open_api_clients, :user_id)

    add_reference :open_api_clients, :user, foreign_key: true
    first_user = User.first
    return unless first_user

    OpenAPI::Client.unscoped.update_all(user_id: first_user.id) # rubocop:disable Rails/SkipsModelValidations
    change_column :open_api_clients, :user_id, :bigint, null: false
  end

  def down
    return unless table_exists?(:open_api_clients)
    return unless column_exists?(:open_api_clients, :user_id)

    remove_reference :open_api_clients, :user, foreign_key: true
  end
end
