# frozen_string_literal: true

# A space reservation added to the shopping cart
class CartItem::SpaceReservation < CartItem::Reservation
  has_many :cart_item_reservation_slots, class_name: 'CartItem::ReservationSlot', dependent: :destroy, inverse_of: :cart_item,
                                         foreign_type: 'cart_item_type', as: :cart_item
  accepts_nested_attributes_for :cart_item_reservation_slots

  belongs_to :operator_profile, class_name: 'InvoicingProfile'
  belongs_to :customer_profile, class_name: 'InvoicingProfile'

  belongs_to :reservable, polymorphic: true

  belongs_to :plan

  def type
    'space'
  end

  def valid?(all_items)
    if reservable.disabled
      errors.add(:reservable, I18n.t('cart_item_validation.space'))
      return false
    end

    super
  end

  protected

  def credits
    return 0 if plan.nil?

    space_credit = plan.space_credits.find { |credit| credit.creditable_id == reservable.id }
    credits_hours(space_credit, new_plan_being_bought: new_subscription)
  end

  def reservation_deadline_minutes
    Setting.get('space_reservation_deadline').to_i
  end
end
