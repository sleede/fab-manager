import { IApplication } from '../../models/application';
import React, { useEffect } from 'react';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import type { Slot } from '../../models/slot';
import { useImmer } from 'use-immer';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';
import { ShoppingCart } from 'phosphor-react';
import CartAPI from '../../api/cart';
import useCart from '../../hooks/use-cart';
import type { User } from '../../models/user';
import Switch from 'react-switch';
import { CartItemReservation } from '../../models/cart_item';
import { ReservableType } from '../../models/reservation';

declare const Application: IApplication;

interface ReservationsSummaryProps {
  slot: Slot,
  customer: User,
  reservableId: number,
  reservableType: ReservableType,
  onError: (error: string) => void,
}

/**
 * Display a summary of the selected slots, and ask for confirmation before adding them to the cart
 */
const ReservationsSummary: React.FC<ReservationsSummaryProps> = ({ slot, customer, reservableId, reservableType, onError }) => {
  const { cart, setCart } = useCart(customer);
  const [pendingSlots, setPendingSlots] = useImmer<Array<Slot>>([]);
  const [offeredSlots, setOfferedSlots] = useImmer<Map<number, boolean>>(new Map());
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
        setPendingSlots(draft => draft.filter(s => s.slot_id !== slot.slot_id));
      } else {
        setPendingSlots(draft => { draft.push(slot); });
      }
    }
  }, [slot]);

  useEffect(() => {
    if (customer && cart) {
      CartAPI.setCustomer(cart, customer.id).then(setCart).catch(onError);
    }
  }, [customer]);

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

  return (
    <div>
      <ul>{pendingSlots.map(slot => (
        <li key={slot.slot_id}>
          <span>{FormatLib.date(slot.start)} {FormatLib.time(slot.start)} - {FormatLib.time(slot.end)}</span>
          <label>offered? <Switch checked={offeredSlots.get(slot.slot_id)} onChange={offerSlot(slot)} /></label>
          <FabButton onClick={addSlotToReservation(slot)}>validate this slot</FabButton>
        </li>
      ))}</ul>
      {reservation.reservation.slots_reservations_attributes.length > 0 && <div>
        <FabButton onClick={addReservationToCart}><ShoppingCart size={24}/>Ajouter au panier</FabButton>
      </div>}
    </div>
  );
};

const ReservationsSummaryWrapper: React.FC<ReservationsSummaryProps> = (props) => (
  <Loader>
    <ReservationsSummary {...props} />
  </Loader>
);

Application.Components.component('reservationsSummary', react2angular(ReservationsSummaryWrapper, ['slot', 'customer', 'reservableId', 'reservableType', 'onError']));
