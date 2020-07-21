# frozen_string_literal: true

# Provides helper methods to compute footprints
class FootprintService
  # Compute the footprint
  # @param klass Invoice|InvoiceItem|HistoryValue
  # @param item an instance of the provided class
  # @param sort the items in database by the provided criterion, to find the previous one
  def self.compute_footprint(klass, item, sort_on = 'id')
    Checksum.text(FootprintService.footprint_data(klass, item, sort_on))
  end

  # Return the original data string used to compute the footprint
  # @param klass Invoice|InvoiceItem|HistoryValue
  # @param item an instance of the provided class
  # @param sort the items in database by the provided criterion, to find the previous one
  def self.footprint_data(klass, item, sort_on = 'id')
    raise TypeError unless item.is_a? klass

    previous = klass.where("#{sort_on} < ?", item[sort_on])
                 .order("#{sort_on} DESC")
                 .limit(1)

    columns  = FootprintService.footprint_columns(klass)

    "#{columns.map { |c| item[c] }.join}#{previous.first ? previous.first.footprint : ''}"
  end

  # Return an ordered array of the columns used in the footprint computation
  # @param klass Invoice|InvoiceItem|HistoryValue
  def self.footprint_columns(klass)
    klass.columns.map(&:name).delete_if { |c| %w[footprint updated_at].include? c }
  end

  # Logs a debugging message to help finding why a footprint is invalid
  # @param klass Invoice|InvoiceItem|HistoryValue
  # @param item an instance of the provided class
  def self.debug_footprint(klass, item)
    columns = FootprintService.footprint_columns(klass)
    current = FootprintService.footprint_data(klass, item)
    saved = FootprintDebug.find_by(footprint: item.footprint, klass: klass)
    puts "Debug footprint for Invoice [ id: #{item.id} ]"
    puts '-----------------------------------------'
    puts "columns: [ #{columns.join(', ')} ]"
    puts "current footprint: #{current}"
    puts "  saved footprint: #{saved&.data}"
    puts '-----------------------------------------'
  end
end
