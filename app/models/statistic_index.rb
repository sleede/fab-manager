class StatisticIndex < ActiveRecord::Base
  has_many :statistic_types
  has_many :statistic_fields
  has_one :statistic_graph
end
