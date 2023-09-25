# frozen_string_literal: true

# Add pre-registration and pre_registration_end_date to event
class AddPreRegistrationToEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :pre_registration, :boolean, default: false
    add_column :events, :pre_registration_end_date, :datetime
  end
end
