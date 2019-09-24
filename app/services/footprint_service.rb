# frozen_string_literal: true

# Provides helper methods to compute footprints
class FootprintService
  # Compute the footprint
  # @param class_name Invoice|InvoiceItem|HistoryValue
  # @param item an instance of the provided class
  # @param sort the items in database by the provided criterion, to find the previous one
  def self.compute_footprint(klass, item, sort_on = 'id')
    raise TypeError unless item.is_a? klass

    previous = klass.where("#{sort_on} < ?", item[sort_on])
                    .order("#{sort_on} DESC")
                    .limit(1)

    columns  = klass.columns.map(&:name)
                    .delete_if { |c| %w[footprint updated_at].include? c }

    Checksum.text("#{columns.map { |c| item[c] }.join}#{previous.first ? previous.first.footprint : ''}")
  end
end
