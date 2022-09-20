# frozen_string_literal: true

# TrainingsMachine is the relation table between a Machine and a Training.
class TrainingsMachine < ApplicationRecord
  belongs_to :machine
  belongs_to :training
end
