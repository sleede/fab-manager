class CreateTrainingsAvailabilities < ActiveRecord::Migration
  def change
    create_table :trainings_availabilities do |t|
      t.belongs_to :training, index: true
      t.belongs_to :availability, index: true

      t.timestamps
    end
  end
end
