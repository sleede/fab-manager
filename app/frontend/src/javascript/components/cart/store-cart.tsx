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

  const { loading, cart, setCart } = useCart();

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

  return (
    <div className="store-cart">
      {loading && <p>loading</p>}
      {cart && cart.order_items_attributes.map(item => (
        <div key={item.id}>
          <div>{item.orderable_name}</div>
          <div>{FormatLib.price(item.amount)}</div>
          <div>{item.quantity}</div>
          <div>{FormatLib.price(item.quantity * item.amount)}</div>
          <FabButton className="delete-btn" onClick={removeProductFromCart(item)}>
            <i className="fa fa-trash" /> {t('app.public.store_cart.remove_item')}
          </FabButton>
        </div>
      ))}
      {cart && <p>{cart.amount}</p>}
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
