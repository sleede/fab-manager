# frozen_string_literal: true

# From this migration, the admins/managers will be able to save a private note per user
class AddNoteToProfile < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :note, :text
  end
end
