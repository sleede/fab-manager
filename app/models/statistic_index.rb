class StatisticIndex < ApplicationRecord
  has_many :statistic_types
  has_many :statistic_fields
  has_one :statistic_graph

  def concerned_by_reservation_context?
    return false unless es_type_key.in? ReservationContext::APPLICABLE_ON
    return false unless Setting.get('reservation_context_feature')

    true
  end
end
