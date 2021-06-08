# frozen_string_literal: true

# Allows to sort plans into categories. Plans are sorted by multiple criterion,
# ordered as follow:
# - group
# - plan_category
# - plan
class PlanCategory < ApplicationRecord
  has_many :plan, dependent: :nullify
end
