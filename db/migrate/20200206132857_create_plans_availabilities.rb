# frozen_string_literal: true

class CreatePlansAvailabilities < ActiveRecord::Migration[4.2]
  def change
    create_table :plans_availabilities do |t|
      t.belongs_to :plan, index: true
      t.belongs_to :availability, index: true
    end
  end
end
