# frozen_string_literal: true

# We save the data provided by the SSO provider in the user table. So we know,
# per user which data was provided or not.
class AddMappedFromSsoToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :mapped_from_sso, :string
  end
end
