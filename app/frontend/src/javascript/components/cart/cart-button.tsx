import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { Order } from '../../models/order';
import { useCustomEventListener } from 'react-custom-events';

declare const Application: IApplication;

/**
 * This component shows my cart button
 */
const CartButton: React.FC = () => {
  const { t } = useTranslation('public');
  const [cart, setCart] = useState<Order>();
  useCustomEventListener<Order>('CartUpdate', (data) => {
    setCart(data);
  });

  /**
   * Goto cart page
   */
  const showCart = () => {
    window.location.href = '/#!/cart';
  };

  return (
    <div className="cart-button" onClick={showCart}>
      <i className="fas fa-cart-arrow-down" />
      {cart && cart.order_items_attributes.length > 0 &&
        <span>{cart.order_items_attributes.length}</span>
      }
      <p>{t('app.public.cart_button.my_cart')}</p>
    </div>
  );
};

const CartButtonWrapper: React.FC = () => {
  return (
    <Loader>
      <CartButton />
    </Loader>
  );
};

Application.Components.component('cartButton', react2angular(CartButtonWrapper));
