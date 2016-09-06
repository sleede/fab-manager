class StatisticType < ActiveRecord::Base
  has_one :statistic_index
  has_many :statistic_type_sub_types
  has_many :statistic_sub_types, through: :statistic_type_sub_types
  has_many :statistic_custom_aggregations
end
