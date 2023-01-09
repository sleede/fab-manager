import * as React from 'react';
import type { OrderErrors, Order } from '../../models/order';
import { useTranslation } from 'react-i18next';
import _ from 'lodash';
import { AbstractItem } from './abstract-item';
import { OrderCartItemReservation } from '../../models/order';
import FormatLib from '../../lib/format';

interface CartOrderReservationProps {
  item: OrderCartItemReservation,
  cartErrors: OrderErrors,
  className?: string,
  cart: Order,
  setCart: (cart: Order) => void,
  reloadCart: () => Promise<void>,
  onError: (message: string) => void,
  privilegedOperator: boolean,
}

/**
 * This component shows a product in the cart
 */
export const CartOrderReservation: React.FC<CartOrderReservationProps> = ({ item, cartErrors, className, cart, setCart, reloadCart, onError, privilegedOperator }) => {
  const { t } = useTranslation('public');

  /**
   * Get the given item's errors
   */
  const getItemErrors = (item: OrderCartItemReservation) => {
    if (!cartErrors) return [];
    const errors = _.find(cartErrors.details, (e) => e.item_id === item.id);
    return errors?.errors || [{ error: 'not_found' }];
  };

  return (
    <AbstractItem className={`cart-order-reservation ${className || ''}`}
                  errors={getItemErrors(item)}
                  item={item}
                  cart={cart}
                  setCart={setCart}
                  onError={onError}
                  reloadCart={reloadCart}
                  actions={<div/>}
                  offerItemLabel={t('app.public.cart_order_reservation.offer_reservation')}
                  privilegedOperator={privilegedOperator}>
      <div className="ref">
        <p>{t('app.public.cart_order_reservation.reservation')} {item.orderable_name}</p>
        <ul>{item.slots_reservations.map(sr => (
          <li key={sr.id}>
            {
              t('app.public.cart_order_reservation.slot',
                { DATE: FormatLib.date(sr.slot.start_at), START: FormatLib.time(sr.slot.start_at), END: FormatLib.time(sr.slot.end_at) })
            }
            <span>{sr.offered ? t('app.public.cart_order_reservation.offered') : ''}</span>
          </li>
        ))}</ul>
        {getItemErrors(item)}
      </div>
    </AbstractItem>
  );
};
