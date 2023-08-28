class ReservationContext < ApplicationRecord
  has_many :reservations
  has_many :cart_item_reservations, dependent: :nullify, class_name: "CartItem::Reservation"

  APPLICABLE_ON = %w[machine space training]

  scope :applicable_on, ->(applicable_on) { where("applicable_on @> ?", "{#{applicable_on.presence_in(APPLICABLE_ON)}}")}

  validates :name, presence: true
  validate :validate_applicable_on

  def safe_destroy
    if reservations.count.zero?
      destroy
    else
      false
    end
  end

  private

  def validate_applicable_on
    return if applicable_on.all? { |applicable_on| applicable_on.in? APPLICABLE_ON }

    errors.add(:applicable_on, :invalid)
  end
end
