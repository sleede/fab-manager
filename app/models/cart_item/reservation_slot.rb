# frozen_string_literal: true

require_relative 'cart_item'

# A relation table between a pending reservation and a slot
class CartItem::ReservationSlot < ApplicationRecord
  self.table_name = 'cart_item_reservation_slots'

  belongs_to :cart_item, polymorphic: true
  belongs_to :cart_item_machine_reservation, foreign_type: 'CartItem::MachineReservation', foreign_key: 'cart_item_id',
                                             inverse_of: :cart_item_reservation_slots, class_name: 'CartItem::MachineReservation'
  belongs_to :cart_item_space_reservation, foreign_type: 'CartItem::SpaceReservation', foreign_key: 'cart_item_id',
                                           inverse_of: :cart_item_reservation_slots, class_name: 'CartItem::SpaceReservation'
  belongs_to :cart_item_training_reservation, foreign_type: 'CartItem::TrainingReservation', foreign_key: 'cart_item_id',
                                              inverse_of: :cart_item_reservation_slots, class_name: 'CartItem::TrainingReservation'
  belongs_to :cart_item_event_reservation, foreign_type: 'CartItem::EventReservation', foreign_key: 'cart_item_id',
                                           inverse_of: :cart_item_reservation_slots, class_name: 'CartItem::EventReservation'

  belongs_to :slot
  belongs_to :slots_reservation
end
