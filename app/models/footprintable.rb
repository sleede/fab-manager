# frozen_string_literal: true

# SuperClass for models that are secured by chained footprints.
class Footprintable < ApplicationRecord
  self.abstract_class = true

  def self.columns_out_of_footprint
    []
  end

  def footprint_children
    []
  end

  def sort_on_field
    'id'
  end

  def check_footprint
    return false unless persisted?

    reload
    footprint_children.map(&:check_footprint).all? && !chained_element.corrupted?
  end

  # @return [ChainedElement]
  def chain_record
    ChainedElement.create!(
      element: self,
      previous: previous_record&.chained_element
    )
  end

  # @return [Footprintable,NilClass]
  def previous_record
    self.class.where("#{sort_on_field} < ?", self[sort_on_field])
        .order("#{sort_on_field} DESC")
        .limit(1)
        .first
  end

  def debug_footprint
    FootprintService.debug_footprint(self.class, self)
  end
end
