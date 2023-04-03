# frozen_string_literal: true

# A relation table between a pending reservation and a slot
class CartItem::ReservationSlot < ApplicationRecord
  self.table_name = 'cart_item_reservation_slots'

  belongs_to :cart_item, polymorphic: true
  belongs_to :cart_item_machine_reservation, foreign_key: 'cart_item_id', class_name: 'CartItem::MachineReservation',
                                             inverse_of: :cart_item_reservation_slots
  belongs_to :cart_item_space_reservation, foreign_key: 'cart_item_id', class_name: 'CartItem::SpaceReservation',
                                           inverse_of: :cart_item_reservation_slots
  belongs_to :cart_item_training_reservation, foreign_key: 'cart_item_id', class_name: 'CartItem::TrainingReservation',
                                              inverse_of: :cart_item_reservation_slots
  belongs_to :cart_item_event_reservation, foreign_key: 'cart_item_id', class_name: 'CartItem::EventReservation',
                                           inverse_of: :cart_item_reservation_slots

  belongs_to :slot
  belongs_to :slots_reservation

  after_create :add_to_places_cache
  after_update :remove_from_places_cache, if: :canceled?

  before_destroy :remove_from_places_cache

  private

  def add_to_places_cache
    update_places_cache(:+)
  end

  def remove_from_places_cache
    update_places_cache(:-)
  end

  # @param operation [Symbol] :+ or :-
  def update_places_cache(operation)
    user_method = operation == :+ ? :add_users : :remove_users
    if cart_item_type == 'CartItem::EventReservation'
      Slots::PlacesCacheService.change_places(slot, 'Event', cart_item.event_id, cart_item.total_tickets, operation)
      Slots::PlacesCacheService.send(user_method,
                                     slot,
                                     'Event',
                                     cart_item.event_id,
                                     [cart_item.customer_profile.user_id])
    else
      Slots::PlacesCacheService.change_places(slot, cart_item.reservable_type, cart_item.reservable_id, 1, operation)
      Slots::PlacesCacheService.send(user_method,
                                     slot,
                                     cart_item.reservable_type,
                                     cart_item.reservable_id,
                                     [cart_item.customer_profile.user_id])
    end
  end
end
