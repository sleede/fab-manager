# frozen_string_literal: true

# Read and write the amount attribute, after converting to/from cents.
module AmountConcern
  extend ActiveSupport::Concern

  included do
    include ApplicationHelper
    validates :amount, numericality: { greater_than_or_equal_to: 0 }

    def amount=(amount)
      if amount.nil?
        write_attribute(:amount, amount)
      else
        write_attribute(:amount, to_centimes(amount))
      end
    end

    def amount
      if read_attribute(:amount).blank?
        read_attribute(:amount)
      else
        read_attribute(:amount) / 100.0
      end
    end
  end
end
