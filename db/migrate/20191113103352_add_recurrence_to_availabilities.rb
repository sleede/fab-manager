# frozen_string_literal: true

# From this migration, we store recurrence info into the availability object, the availability can be linked to others, which are
# its "children".
class AddRecurrenceToAvailabilities < ActiveRecord::Migration[4.2]
  def change
    add_column :availabilities, :is_recurrent, :boolean
    add_column :availabilities, :occurrence_id, :integer
    add_column :availabilities, :period, :string
    add_column :availabilities, :nb_periods, :integer
    add_column :availabilities, :end_date, :datetime
  end
end
