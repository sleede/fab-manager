import { ReservableType } from './reservation';
import { SubscriptionRequest } from './subscription';

export type CartItem = Record<string, unknown>;

export interface CartItemReservationSlot {
  offered: boolean,
  slot_id: number,
}

export interface CartItemReservation extends CartItem {
  reservation: {
    reservable_id: number,
    reservable_type: ReservableType,
    slots_reservations_attributes: Array<CartItemReservationSlot>
  }
}

export interface CartItemEventReservation extends CartItem {
  reservation: {
    reservable_id: number,
    reservable_type: 'Event',
    slots_reservations_attributes: Array<CartItemReservationSlot>
    nb_reserve_places: number,
    tickets_attributes?: {
      event_price_category_id: number,
      booked: number
    }
  }
}
export interface CartItemSubscription extends CartItem {
  subscription: SubscriptionRequest
}

export interface CartItemPrepaidPack extends CartItem {
  prepaid_pack: { id: number }
}

export interface CartItemFreeExtension extends CartItem {
  free_extension: { end_at: Date }
}

export type CartItemType = 'CartItem::EventReservation' | 'CartItem::MachineReservation' | 'CartItem::PrepaidPack' | 'CartItem::SpaceReservation' | 'CartItem::Subscription' | 'CartItem::TrainingReservation';

export interface CartItemResponse {
  id: number,
  type: CartItemType
}
