# frozen_string_literal: true

# From this migration, we allows trainings to be valid for a maximum duration, after
# the configured period, the member must validate a new training session.
# Moreover, we allows to configure automatic cancellation of the training validity
# if the member has not used the associated machines for a configurable duration
class AddAuthorizationToTrainings < ActiveRecord::Migration[5.2]
  def change
    change_table :trainings, bulk: true do |t|
      t.boolean :authorization
      t.integer :authorization_period
      t.boolean :invalidation
      t.integer :invalidation_period
    end
  end
end
