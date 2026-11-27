# frozen_string_literal: true

# Run with the PostgreSQL 18 compatible application against a quiesced copy before and after restore.
# Do not regenerate chains: an invalid footprint is a migration blocker.
require 'json'

ActiveRecord::Base.transaction do
  ActiveRecord::Base.connection.execute('SET TRANSACTION READ ONLY')
  models = [Invoice, InvoiceItem, HistoryValue, PaymentSchedule, PaymentScheduleItem, PaymentScheduleObject]
  counts = models.to_h do |model|
    model.order(:id).find_each do |record|
      raise "Invalid footprint: #{model.name} id=#{record.id}" unless record.check_footprint
    end
    [model.name, model.count]
  end
  duplicates = ActiveRecord::Base.connection.select_all(
    'SELECT element_type, element_id, COUNT(*) AS count FROM chained_elements ' \
    'GROUP BY element_type, element_id HAVING COUNT(*) > 1 ORDER BY element_type, element_id'
  ).to_a
  puts JSON.generate(footprint_counts: counts, duplicated_chain_elements: duplicates,
                     reservations: Reservation.count, projects: Project.count)
  raise ActiveRecord::Rollback
end
