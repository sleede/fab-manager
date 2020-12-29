# frozen_string_literal: true

# SuperClass for models that provides legal PDF documents concerning sales
class PaymentDocument < Footprintable
  self.abstract_class = true

  def generate_reference(date = DateTime.current)
    self.reference = PaymentDocumentService.generate_reference(self, date: date)
  end

  def update_reference
    generate_reference
    save
  end

  def add_environment
    self.environment = Rails.env
  end

  def set_wallet_transaction(amount, transaction_id)
    self.wallet_amount = amount
    self.wallet_transaction_id = transaction_id
  end

  def post_save(arg); end
end
