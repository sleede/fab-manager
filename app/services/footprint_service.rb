# frozen_string_literal: true

require 'integrity/checksum'
require 'json'

# Provides helper methods to compute footprints
class FootprintService
  class << self
    # @param item [Footprintable]
    # @param previous_footprint [String,NilClass]
    # @param columns [Array<String>]
    # @return [Hash<Symbol->String,Integer,Hash>]
    def chained_data(item, previous_footprint = nil, columns = nil)
      columns ||= footprint_columns(item.class)
      res = {}
      columns.each do |column|
        next if column.blank? || item[column].blank?

        res[column] = comparable(item[column])
      rescue ActiveModel::MissingAttributeError
        res[column] = nil
      end
      res['previous'] = previous_footprint
      res.sort.to_h
    end

    # Return an ordered array of the columns used in the footprint computation
    # @param klass [Class] a class inheriting from Footprintable
    def footprint_columns(klass)
      %w[id].concat(klass.columns.map(&:name).delete_if do |column|
        %w[id footprint updated_at].concat(klass.columns_out_of_footprint).include?(column)
      end.sort)
    end

    # Logs a debugging message to help finding why a footprint is invalid
    # @param klass [Class] a class inheriting from Footprintable
    # @param item [Footprintable] an instance of the provided class
    def debug_footprint(klass, item)
      current = chained_data(item, item.chained_element.previous&.footprint, item.chained_element.columns)
      saved = item.chained_element&.content&.sort&.to_h&.transform_values { |val| val.is_a?(Hash) ? val.sort.to_h : val }

      if saved.nil?
        " #{klass} [ id: #{item.id} ] is not chained"
      else
        "Debug footprint for #{klass} [ id: #{item.id} ]\n" \
        "-----------------------------------------\n" \
        "=== current ===\n#{JSON.pretty_generate(current)}\n\n=== saved ===\n#{JSON.pretty_generate(saved)}\n" \
        "-----------------------------------------\n" +
          item.footprint_children.map(&:debug_footprint).join("\n\n")
      end
    end

    private

    # Return a comparable value for jsonb fields (with keys ordered alphabetically)
    def comparable(value)
      return value.iso8601 if value.is_a? Time
      return value unless value.is_a? Hash

      value.sort.to_h.transform_values! { |v| comparable(v) }
    end
  end
end
