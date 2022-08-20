import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import useCart from '../../hooks/use-cart';
import FormatLib from '../../lib/format';
import CartAPI from '../../api/cart';

declare const Application: IApplication;

interface StoreCartProps {
  onError: (message: string) => void,
}

/**
 * This component shows user's cart
 */
const StoreCart: React.FC<StoreCartProps> = ({ onError }) => {
  const { t } = useTranslation('public');

  const { cart, setCart } = useCart();

  /**
   * Remove the product from cart
   */
  const removeProductFromCart = (item) => {
    return (e: React.BaseSyntheticEvent) => {
      e.preventDefault();
      e.stopPropagation();
      CartAPI.removeItem(cart, item.orderable_id).then(data => {
        setCart(data);
      });
    };
  };

  /**
   * Change product quantity
   */
  const changeProductQuantity = (item) => {
    return (e: React.BaseSyntheticEvent) => {
      CartAPI.setQuantity(cart, item.orderable_id, e.target.value).then(data => {
        setCart(data);
      });
    };
  };

  /**
   * Checkout cart
   */
  const checkout = () => {
    console.log('checkout .....');
  };

  return (
    <div className="store-cart">
      {cart && cart.order_items_attributes.map(item => (
        <div key={item.id}>
          <div>{item.orderable_name}</div>
          <div>{FormatLib.price(item.amount)}</div>
          <div>{item.quantity}</div>
          <select value={item.quantity} onChange={changeProductQuantity(item)}>
            {Array.from({ length: 100 }, (_, i) => i + 1).map(v => (
              <option key={v} value={v}>{v}</option>
            ))}
          </select>
          <div>{FormatLib.price(item.quantity * item.amount)}</div>
          <FabButton className="delete-btn" onClick={removeProductFromCart(item)}>
            <i className="fa fa-trash" />
          </FabButton>
        </div>
      ))}
      {cart && <p>Totale: {FormatLib.price(cart.amount)}</p>}
      <FabButton className="checkout-btn" onClick={checkout}>
        {t('app.public.store_cart.checkout')}
      </FabButton>
    </div>
  );
};

const StoreCartWrapper: React.FC<StoreCartProps> = ({ onError }) => {
  return (
    <Loader>
      <StoreCart onError={onError} />
    </Loader>
  );
};

Application.Components.component('storeCart', react2angular(StoreCartWrapper, ['onError']));
