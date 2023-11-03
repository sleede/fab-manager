class StatisticSubType < ApplicationRecord
  include LabelI18nConcern

  has_many :statistic_type_sub_types, dependent: :destroy
  has_many :statistic_types, through: :statistic_type_sub_types
end
