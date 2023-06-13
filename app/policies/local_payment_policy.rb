# frozen_string_literal: true

# Check the access policies for API::LocalPaymentsController
class LocalPaymentPolicy < ApplicationPolicy
  def confirm_payment?
    # only admins and managers can offer free extensions of a subscription
    has_free_days = record.shopping_cart.items.any? { |item| item.is_a? CartItem::FreeExtension }
    event = record.shopping_cart.items.find { |item| item.is_a? CartItem::EventReservation }

    ((user.admin? || user.manager?) && record.shopping_cart.customer.id != user.id) || (record.price.zero? && !has_free_days) || event&.reservable&.pre_registration
  end
end
