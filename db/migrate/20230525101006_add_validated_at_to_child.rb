# frozen_string_literal: true

# add validated_at to child
class AddValidatedAtToChild < ActiveRecord::Migration[7.0]
  def change
    add_column :children, :validated_at, :datetime
  end
end
