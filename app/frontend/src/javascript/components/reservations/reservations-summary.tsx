import React, { ReactNode, useEffect, useState } from 'react';
import type { Slot } from '../../models/slot';
import { useImmer } from 'use-immer';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';
import { ShoppingCart } from 'phosphor-react';
import CartAPI from '../../api/cart';
import type { User } from '../../models/user';
import Switch from 'react-switch';
import { CartItemReservation } from '../../models/cart_item';
import { ReservableType } from '../../models/reservation';
import { Order } from '../../models/order';
import PriceAPI from '../../api/price';
import { PaymentMethod } from '../../models/payment';
import { ComputePriceResult } from '../../models/price';

interface ReservationsSummaryProps {
  slot: Slot,
  customer: User,
  reservableId: number,
  reservableType: ReservableType,
  onError: (error: string) => void,
  cart: Order,
  setCart: (cart: Order) => void,
  onSlotAdded: (slot: Slot) => void,
  onSlotRemoved: (slot: Slot) => void,
}

/**
 * Display a summary of the selected slots, and ask for confirmation before adding them to the cart
 */
export const ReservationsSummary: React.FC<ReservationsSummaryProps> = ({ slot, customer, reservableId, reservableType, onError, cart, setCart, onSlotAdded, onSlotRemoved }) => {
  const [pendingSlots, setPendingSlots] = useImmer<Array<Slot>>([]);
  const [offeredSlots, setOfferedSlots] = useImmer<Map<number, boolean>>(new Map());
  const [price, setPrice] = useState<ComputePriceResult>(null);
  const [reservation, setReservation] = useImmer<CartItemReservation>({
    reservation: {
      reservable_id: reservableId,
      reservable_type: reservableType,
      slots_reservations_attributes: []
    }
  });

  useEffect(() => {
    if (slot) {
      if (pendingSlots.find(s => s.slot_id === slot.slot_id)) {
        removeSlot(slot)();
      } else {
        addSlot(slot);
      }
    }
  }, [slot]);

  useEffect(() => {
    if (!customer) return;

    PriceAPI.compute({
      customer_id: customer.id,
      items: [reservation],
      payment_method: PaymentMethod.Other
    }).then(setPrice).catch(onError);
  }, [reservation]);

  /**
   * Add a new slot to the pending list
   */
  const addSlot = (slot: Slot) => {
    setPendingSlots(draft => { draft.push(slot); });
    if (typeof onSlotAdded === 'function') onSlotAdded(slot);
  };

  /**
   * Add the product to cart
   */
  const addSlotToReservation = (slot: Slot) => {
    return () => {
      setReservation(draft => {
        draft.reservation.slots_reservations_attributes.push({
          slot_id: slot.slot_id,
          offered: !!offeredSlots.get(slot.slot_id)
        });
      });
    };
  };

  /**
   * Check if the reservation contains the given slot
   */
  const isSlotInReservation = (slot: Slot): boolean => {
    return reservation.reservation.slots_reservations_attributes.filter(s => s.slot_id === slot.slot_id).length > 0;
  };

  /**
   * Removes the given slot from the reservation (if applicable) and trigger the onSlotRemoved callback
   */
  const removeSlot = (slot: Slot) => {
    return () => {
      if (isSlotInReservation(slot)) {
        setReservation(draft => {
          return {
            reservation: {
              ...draft.reservation,
              slots_reservations_attributes: draft.reservation.slots_reservations_attributes.filter(sr => sr.slot_id !== slot.slot_id)
            }
          };
        });
      }
      setPendingSlots(draft => draft.filter(s => s.slot_id !== slot.slot_id));
      if (typeof onSlotRemoved === 'function') onSlotRemoved(slot);
    };
  };

  /**
   * Build / validate the reservation at server-side, then add it to the cart.
   */
  const addReservationToCart = async () => {
    try {
      const item = await CartAPI.createItem(cart, reservation);
      const newCart = await CartAPI.addItem(cart, item.id, item.type, 1);
      setCart(newCart);
    } catch (e) {
      onError(e);
    }
  };

  /**
   * Toggle the "offered" status of the given slot
   */
  const offerSlot = (slot: Slot) => {
    return () => {
      setOfferedSlots(draft => {
        draft.set(slot.slot_id, !draft.get(slot.slot_id));
      });
    };
  };

  /**
   * Return the price of the given slot, if known
   */
  const slotPrice = (slot: Slot): string => {
    if (!price) return '';

    const slotPrice = price.details.slots.find(s => s.slot_id === slot.slot_id);
    if (!slotPrice) return '';

    return FormatLib.price(slotPrice.price);
  };

  /**
   * Return the total price for the current reservation
   */
  const total = (): ReactNode => {
    if (!price || reservation.reservation.slots_reservations_attributes.length === 0) return '';

    return <span>TOTAL: {FormatLib.price(price?.price)}</span>;
  };

  return (
    <div>
      <ul>{pendingSlots.map(slot => (
        <li key={slot.slot_id}>
          <span>{FormatLib.date(slot.start)} {FormatLib.time(slot.start)} - {FormatLib.time(slot.end)}</span>
          <label>offered? <Switch checked={offeredSlots.get(slot.slot_id) || false} onChange={offerSlot(slot)} /></label>
          <span className="price">{slotPrice(slot)}</span>
          {!isSlotInReservation(slot) && <FabButton onClick={addSlotToReservation(slot)}>Ajouter à la réservation</FabButton>}
          <FabButton onClick={removeSlot(slot)}>Enlever</FabButton>
        </li>
      ))}</ul>
      {total()}
      {reservation.reservation.slots_reservations_attributes.length > 0 && <div>
        <FabButton onClick={addReservationToCart}><ShoppingCart size={24}/>Ajouter au panier</FabButton>
      </div>}
    </div>
  );
};
