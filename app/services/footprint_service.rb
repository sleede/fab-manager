# frozen_string_literal: true

require 'checksum'

# Provides helper methods to compute footprints
class FootprintService
  class << self
    # Compute the footprint
    # @param klass a class inheriting from Footprintable
    # @param item an instance of the provided class
    # @param sort_on the items in database by the provided criterion, to find the previous one
    def compute_footprint(klass, item, sort_on = 'id')
      Checksum.text(FootprintService.footprint_data(klass, item, sort_on))
    end

    # Return the original data string used to compute the footprint
    # @param klass a class inheriting from Footprintable
    # @param item an instance of the provided class
    # @param sort_on the items in database by the provided criterion, to find the previous one
    def footprint_data(klass, item, sort_on = 'id')
      raise TypeError unless item.is_a? klass

      previous = klass.where("#{sort_on} < ?", item[sort_on])
                   .order("#{sort_on} DESC")
                   .limit(1)

      columns  = FootprintService.footprint_columns(klass)

      "#{columns.map { |c| comparable(item[c]) }.join}#{previous.first ? previous.first.footprint : ''}"
    end

    # Return an ordered array of the columns used in the footprint computation
    # @param klass a class inheriting from Footprintable
    def footprint_columns(klass)
      klass.columns.map(&:name).delete_if { |c| %w[footprint updated_at].concat(klass.columns_out_of_footprint).include? c }
    end

    # Logs a debugging message to help finding why a footprint is invalid
    # @param klass a class inheriting from Footprintable
    # @param item an instance of the provided class
    def debug_footprint(klass, item)
      columns = FootprintService.footprint_columns(klass)
      current = FootprintService.footprint_data(klass, item)
      saved = FootprintDebug.find_by(footprint: item.footprint, klass: klass.name)
      puts "Debug footprint for #{klass} [ id: #{item.id} ]"
      puts '-----------------------------------------'
      puts "columns: [ #{columns.join(', ')} ]"
      puts "current: #{current}"
      puts "  saved: #{saved&.data}"
      puts '-----------------------------------------'
    end

    private

    # Return a comparable value for jsonb fields (with keys ordered alphabetically)
    def comparable(value)
      return value unless value.class == Hash

      value.sort.to_h
    end
  end
end
