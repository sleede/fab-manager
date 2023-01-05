import * as React from 'react';
import type { OrderErrors, Order } from '../../models/order';
import { useTranslation } from 'react-i18next';
import _ from 'lodash';
import { AbstractItem } from './abstract-item';
import { OrderCartItem } from '../../models/order';

interface CartOrderReservationProps {
  item: OrderCartItem,
  cartErrors: OrderErrors,
  className?: string,
  cart: Order,
  setCart: (cart: Order) => void,
  onError: (message: string) => void,
  removeProductFromCart: (item: OrderCartItem) => void,
  toggleProductOffer: (item: OrderCartItem, checked: boolean) => void,
  privilegedOperator: boolean,
}

/**
 * This component shows a product in the cart
 */
export const CartOrderReservation: React.FC<CartOrderReservationProps> = ({ item, cartErrors, className, cart, setCart, onError, removeProductFromCart, toggleProductOffer, privilegedOperator }) => {
  const { t } = useTranslation('public');

  /**
   * Get the given item's errors
   */
  const getItemErrors = (item: OrderCartItem) => {
    if (!cartErrors) return [];
    const errors = _.find(cartErrors.details, (e) => e.item_id === item.id);
    return errors?.errors || [{ error: 'not_found' }];
  };

  return (
    <AbstractItem className={`cart-order-reservation ${className || ''}`}
                  hasError={getItemErrors(item).length > 0}
                  item={item}
                  removeItemFromCart={removeProductFromCart}
                  privilegedOperator={privilegedOperator}
                  toggleItemOffer={toggleProductOffer}>
      <div className="ref">
        <p>Réservation {item.orderable_name}</p>
        {getItemErrors(item)}
      </div>
    </AbstractItem>
  );
};
