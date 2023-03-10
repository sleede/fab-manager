# frozen_string_literal: true

# Allows to set booking limits on some resources, per plan.
class PlanLimitation < ApplicationRecord
  belongs_to :plan

  belongs_to :limitable, polymorphic: true
  belongs_to :machine, foreign_type: 'Machine', foreign_key: 'limitable_id', inverse_of: :plan_limitations
  belongs_to :machine_category, foreign_type: 'MachineCategory', foreign_key: 'limitable_id', inverse_of: :plan_limitations

  validates :limitable_id, :limitable_type, :limit, :plan_id, presence: true
  validates :limitable_id, uniqueness: { scope: %i[limitable_type plan_id] }
end
