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

declare const Application: IApplication;

interface ReservationsSummaryProps {
  slot: Slot,
  customer: User,
  onError: (error: string) => void,
}

/**
 * Display a summary of the selected slots, and ask for confirmation before adding them to the cart
 */
const ReservationsSummary: React.FC<ReservationsSummaryProps> = ({ slot, customer, onError }) => {
  const { cart, setCart } = useCart(customer);
  const [pendingSlots, setPendingSlots] = useImmer<Array<Slot>>([]);

  useEffect(() => {
    if (slot) {
      if (pendingSlots.find(s => s.slot_id === slot.slot_id)) {
        setPendingSlots(draft => draft.filter(s => s.slot_id !== slot.slot_id));
      } else {
        setPendingSlots(draft => { draft.push(slot); });
      }
    }
  }, [slot]);

  /**
   * Add the product to cart
   */
  const addSlotToCart = (slot: Slot) => {
    return () => {
      CartAPI.addItem(cart, slot.slot_id, 'Slot', 1).then(setCart).catch(onError);
    };
  };

  return (
    <ul>{pendingSlots.map(slot => (
      <li key={slot.slot_id}>
        <span>{FormatLib.date(slot.start)} {FormatLib.time(slot.start)} - {FormatLib.time(slot.end)}</span>
        <FabButton onClick={addSlotToCart(slot)}><ShoppingCart size={24}/> add to cart </FabButton>
      </li>
    ))}</ul>
  );
};

const ReservationsSummaryWrapper: React.FC<ReservationsSummaryProps> = (props) => (
  <Loader>
    <ReservationsSummary {...props} />
  </Loader>
);

Application.Components.component('reservationsSummary', react2angular(ReservationsSummaryWrapper, ['slot', 'customer', 'onError']));
