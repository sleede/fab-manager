class StatisticIndex < ApplicationRecord
  include LabelI18nConcern

  has_many :statistic_types
  has_many :statistic_fields
  has_one :statistic_graph

  def concerned_by_reservation_context?
    return false unless es_type_key.in? ReservationContext::APPLICABLE_ON
    return false unless Setting.get('reservation_context_feature')

    true
  end

  def show_coupon?
    es_type_key.in? %w[subscription machine training event space order]
  end
end
