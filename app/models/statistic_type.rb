# frozen_string_literal: true

# Allows splinting a StatisticIndex into multiple types.
# e.g. The StatisticIndex "subscriptions" may have types like "1 month", "1 year", etc.
class StatisticType < ApplicationRecord
  belongs_to :statistic_index
  has_many :statistic_type_sub_types, dependent: :destroy
  has_many :statistic_sub_types, through: :statistic_type_sub_types
  has_many :statistic_custom_aggregations, dependent: :destroy
end
