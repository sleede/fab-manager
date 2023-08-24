class CreateReservationContexts < ActiveRecord::Migration[7.0]
  def change
    create_table :reservation_contexts do |t|
      t.string :name
      t.string :applicable_on, array: true, default: []

      t.timestamps
    end
  end
end
