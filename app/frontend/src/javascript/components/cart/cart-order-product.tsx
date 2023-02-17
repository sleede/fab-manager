import * as React from 'react';
import FormatLib from '../../lib/format';
import { CaretDown, CaretUp } from 'phosphor-react';
import type { OrderProduct, OrderErrors, Order, ItemError } from '../../models/order';
import { useTranslation } from 'react-i18next';
import _ from 'lodash';
import CartAPI from '../../api/cart';
import { AbstractItem } from './abstract-item';
import { ReactNode } from 'react';

interface CartOrderProductProps {
  item: OrderProduct,
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
export const CartOrderProduct: React.FC<CartOrderProductProps> = ({ item, cartErrors, className, cart, setCart, reloadCart, onError, privilegedOperator }) => {
  const { t } = useTranslation('public');

  /**
   * Get the given item's errors
   */
  const getItemErrors = (item: OrderProduct): Array<ItemError> => {
    if (!cartErrors) return [];
    const errors = _.find(cartErrors.details, (e) => e.item_id === item.id);
    return errors?.errors || [{ error: 'not_found' }];
  };

  /**
   * Show an human-readable styled error for the given item's error
   */
  const itemError = (item: OrderProduct, error) => {
    if (error.error === 'is_active' || error.error === 'not_found') {
      return <div className='error'><p>{t('app.public.cart_order_product.errors.product_not_found')}</p></div>;
    }
    if (error.error === 'stock' && error.value === 0) {
      return <div className='error'><p>{t('app.public.cart_order_product.errors.out_of_stock')}</p></div>;
    }
    if (error.error === 'stock' && error.value > 0) {
      return <div className='error'><p>{t('app.public.cart_order_product.errors.stock_limit_QUANTITY', { QUANTITY: error.value })}</p></div>;
    }
    if (error.error === 'quantity_min') {
      return <div className='error'><p>{t('app.public.cart_order_product.errors.quantity_min_QUANTITY', { QUANTITY: error.value })}</p></div>;
    }
    if (error.error === 'amount') {
      return <div className='error'>
        <p>{t('app.public.cart_order_product.errors.price_changed_PRICE', { PRICE: `${FormatLib.price(error.value)} / ${t('app.public.cart_order_product.unit')}` })}</p>
        <span className='refresh-btn' onClick={refreshItem(item)}>{t('app.public.cart_order_product.update_item')}</span>
      </div>;
    }
  };

  /**
   * Refresh product amount
   */
  const refreshItem = (item: OrderProduct) => {
    return (e: React.BaseSyntheticEvent) => {
      e.preventDefault();
      e.stopPropagation();
      CartAPI.refreshItem(cart, item.orderable_id, item.orderable_type).then(data => {
        setCart(data);
      }).catch(onError);
    };
  };

  /**
   * Change product quantity
   */
  const changeProductQuantity = (e: React.BaseSyntheticEvent, item: OrderProduct) => {
    CartAPI.setQuantity(cart, item.orderable_id, item.orderable_type, e.target.value)
      .then(data => {
        setCart(data);
      })
      .catch(() => onError(t('app.public.cart_order_product.stock_limit')));
  };

  /**
   * Increment/decrement product quantity
   */
  const increaseOrDecreaseProductQuantity = (item: OrderProduct, direction: 'up' | 'down') => {
    CartAPI.setQuantity(cart, item.orderable_id, item.orderable_type, direction === 'up' ? item.quantity + 1 : item.quantity - 1)
      .then(data => {
        setCart(data);
      })
      .catch(() => onError(t('app.public.cart_order_product.stock_limit')));
  };

  /**
   * Return the components in the "actions" section of the item
   */
  const buildActions = (): ReactNode => {
    return (
      <>
        <div className='price'>
          <p>{FormatLib.price(item.amount)}</p>
          <span>/ {t('app.public.cart_order_product.unit')}</span>
        </div>
      <div className='quantity'>
        <input type='number'
               onChange={e => changeProductQuantity(e, item)}
               min={item.quantity_min}
               max={item.orderable_external_stock}
               value={item.quantity}
        />
        <button onClick={() => increaseOrDecreaseProductQuantity(item, 'up')}><CaretUp size={12} weight="fill" /></button>
        <button onClick={() => increaseOrDecreaseProductQuantity(item, 'down')}><CaretDown size={12} weight="fill" /></button>
      </div>
      </>
    );
  };

  return (
    <AbstractItem className={`cart-order-product ${className || ''}`}
                  errors={getItemErrors(item)}
                  setCart={setCart}
                  cart={cart}
                  onError={onError}
                  reloadCart={reloadCart}
                  item={item}
                  privilegedOperator={privilegedOperator}
                  actions={buildActions()}>
      <div className="ref">
        <span>{t('app.public.cart_order_product.reference_short')} {item.orderable_ref || ''}</span>
        <p><a className="text-black" href={`/#!/store/p/${item.orderable_slug}`}>{item.orderable_name}</a></p>
        {item.quantity_min > 1 &&
          <span className='min'>{t('app.public.cart_order_product.minimum_purchase')}{item.quantity_min}</span>
        }
        {getItemErrors(item).map(e => {
          return itemError(item, e);
        })}
      </div>
    </AbstractItem>
  );
};
