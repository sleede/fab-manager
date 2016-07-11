module AmountConcern
  extend ActiveSupport::Concern

  included do
    validates_numericality_of :amount, greater_than_or_equal_to: 0

    def amount=(amount)
      if amount.nil?
        write_attribute(:amount, amount)
      else
        write_attribute(:amount, (amount * 100).to_i)
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
