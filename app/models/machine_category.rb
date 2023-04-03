# frozen_string_literal: true

# MachineCategory used to categorize Machines.
class MachineCategory < ApplicationRecord
  has_many :machines, dependent: :nullify
  accepts_nested_attributes_for :machines, allow_destroy: true
  has_many :plan_limitations, dependent: :destroy, inverse_of: :machine_category, foreign_type: 'limitable_type', as: :limitable
end
