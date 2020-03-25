# frozen_string_literal: true

# Role is a authorization level for users in the application.
# Currently, possible roles are: admin or member
class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: 'users_roles'
  belongs_to :resource, polymorphic: true

  scopify
end
