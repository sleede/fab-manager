# frozen_string_literal: true

require 'integrity/checksum'
require 'json'

# ChainedElement saves data about a securly footprinted chained element (like invoices)
class ChainedElement < ApplicationRecord
  belongs_to :element, polymorphic: true
  belongs_to :previous, class_name: 'ChainedElement'
  has_one :next, class_name: 'ChainedElement', inverse_of: :previous, dependent: :restrict_with_exception

  before_create :set_content, :chain_record

  validates :element_id, :element_type, presence: true

  # @return [Boolean]
  def corrupted?
    comparable(FootprintService.chained_data(element, previous&.footprint, columns)) != comparable(content) ||
      footprint != Integrity::Checksum.text(comparable(content).to_json)
  end

  # return ths list of columns in the saved JSON. This is used to do the comparison with the
  # saved item, as it may have changed between (some columns may have been added)
  # @return [Array<String>]
  def columns
    %w[id].concat(content.keys.delete_if do |column|
      %w[id previous].concat(element.class.columns_out_of_footprint).include?(column)
    end.sort)
  end

  private

  def set_content
    self.content = FootprintService.chained_data(element, previous&.footprint)
  end

  def chain_record
    self.footprint = Integrity::Checksum.text(content.to_json)
  end

  # @param item [Hash]
  # @return [Hash]
  def comparable(item)
    item.sort.to_h.transform_values { |val| val.is_a?(Hash) ? val.sort.to_h : val }
  end
end
