# frozen_string_literal: true

# SuperClass for models that provides legal PDF documents concerning sales
class PaymentDocument < Footprintable
  self.abstract_class = true

  def generate_reference(date = created_at)
    self.reference = PaymentDocumentService.generate_reference(self, date: date)
  end

  def generate_order_number
    self.order_number = PaymentDocumentService.generate_order_number(self)
  end

  def update_reference
    generate_reference if reference.blank?
    save
  end

  def add_environment
    self.environment = Rails.env
  end

  def set_wallet_transaction(amount, transaction_id)
    self.wallet_amount = amount
    self.wallet_transaction_id = transaction_id
  end

  def post_save(*args); end

  def render_resource; end
end
