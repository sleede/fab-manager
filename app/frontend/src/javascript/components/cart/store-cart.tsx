import { useState, useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import type { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import useCart from '../../hooks/use-cart';
import FormatLib from '../../lib/format';
import CartAPI from '../../api/cart';
import type { User } from '../../models/user';
import { PaymentModal } from '../payment/stripe/payment-modal';
import { PaymentMethod } from '../../models/payment';
import type { Order, OrderCartItemReservation, OrderErrors, OrderProduct } from '../../models/order';
import { MemberSelect } from '../user/member-select';
import { CouponInput } from '../coupon/coupon-input';
import type { Coupon } from '../../models/coupon';
import OrderLib from '../../lib/order';
import _ from 'lodash';
import OrderAPI from '../../api/order';
import { CartOrderProduct } from './cart-order-product';
import { CartOrderReservation } from './cart-order-reservation';

declare const Application: IApplication;

interface StoreCartProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  userLogin: () => void,
  currentUser?: User
}

/**
 * This component shows user's cart
 */
const StoreCart: React.FC<StoreCartProps> = ({ onSuccess, onError, currentUser, userLogin }) => {
  const { t } = useTranslation('public');

  const { cart, setCart, reloadCart } = useCart(currentUser);
  const [cartErrors, setCartErrors] = useState<OrderErrors>(null);
  const [noMemberError, setNoMemberError] = useState<boolean>(false);
  const [paymentModal, setPaymentModal] = useState<boolean>(false);
  const [withdrawalInstructions, setWithdrawalInstructions] = useState<string>(null);

  useEffect(() => {
    if (cart) {
      checkCart();
    }
    if (cart && !withdrawalInstructions) {
      OrderAPI.withdrawalInstructions(cart)
        .then(setWithdrawalInstructions)
        .catch(onError);
    }
  }, [cart]);

  /**
   * Check the current cart's items (available, price, stock, quantity_min)
   */
  const checkCart = async (): Promise<OrderErrors> => {
    const errors = await CartAPI.validate(cart);
    setCartErrors(errors);
    return errors;
  };

  /**
   * Checkout cart
   */
  const checkout = () => {
    if (!currentUser) {
      userLogin();
    } else {
      if (!cart.user) {
        setNoMemberError(true);
        onError(t('app.public.store_cart.select_user'));
      } else {
        setNoMemberError(false);
        checkCart().then(errors => {
          if (!hasCartErrors(errors)) {
            setPaymentModal(true);
          }
        });
      }
    }
  };

  /**
   * Check if the carrent cart has any error
   */
  const hasCartErrors = (errors: OrderErrors) => {
    if (!errors) return false;
    for (const item of cart.order_items_attributes) {
      const error = _.find(errors.details, (e) => e.item_id === item.id);
      if (!error || error?.errors?.length > 0) return true;
    }
    return false;
  };

  /**
   * Open/closes the payment modal
   */
  const togglePaymentModal = (): void => {
    setPaymentModal(!paymentModal);
  };

  /**
   * Handle payment
   */
  const handlePaymentSuccess = (data: Order): void => {
    if (data.state === 'paid') {
      setPaymentModal(false);
      window.location.href = '/#!/store';
      onSuccess(t('app.public.store_cart.checkout_success'));
    } else {
      onError(t('app.public.store_cart.checkout_error'));
    }
  };

  /**
   * Change cart's customer by admin/manager
   */
  const handleChangeMember = (user: User): void => {
    CartAPI.setCustomer(cart, user.id).then(setCart).catch(onError);
  };

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (currentUser?.role === 'admin' || currentUser?.role === 'manager');
  };

  /**
   * Check if the current cart is empty ?
   */
  const cartIsEmpty = (): boolean => {
    return cart && cart.order_items_attributes.length === 0;
  };

  /**
   * Apply coupon to current cart
   */
  const applyCoupon = (coupon?: Coupon): void => {
    if (coupon !== cart.coupon) {
      setCart({ ...cart, coupon });
    }
  };

  return (
    <div className='store-cart'>
      <div className="store-cart-list">
        {cart && cartIsEmpty() && <p>{t('app.public.store_cart.cart_is_empty')}</p>}
        {cart && cart.order_items_attributes.map(item => {
          if (item.orderable_type === 'Product') {
            return (
              <CartOrderProduct item={item as OrderProduct}
                                key={item.id}
                                className="store-cart-list-item"
                                cartErrors={cartErrors}
                                cart={cart}
                                setCart={setCart}
                                reloadCart={reloadCart}
                                onError={onError}
                                privilegedOperator={isPrivileged()} />
            );
          }
          return (
            <CartOrderReservation item={item as OrderCartItemReservation}
                                  key={item.id}
                                  className="store-cart-list-item"
                                  cartErrors={cartErrors}
                                  cart={cart}
                                  reloadCart={reloadCart}
                                  setCart={setCart}
                                  onError={onError}
                                  privilegedOperator={isPrivileged()} />
          );
        })}
      </div>

      <div className="group">
        {cart && !cartIsEmpty() &&
          <div className='store-cart-info'>
            <h3>{t('app.public.store_cart.pickup')}</h3>
            <p dangerouslySetInnerHTML={{ __html: withdrawalInstructions }} />
          </div>
        }

        {cart && !cartIsEmpty() &&
          <div className='store-cart-coupon'>
            <CouponInput user={cart.user as User} amount={cart.total} onChange={applyCoupon} />
          </div>
        }
      </div>

      <aside>
        {cart && !cartIsEmpty() && isPrivileged() &&
          <div> <MemberSelect onSelected={handleChangeMember} defaultUser={cart.user as User} hasError={noMemberError} /></div>
        }

        {cart && !cartIsEmpty() && <>
          <div className="checkout">
            <h3>{t('app.public.store_cart.checkout_header')}</h3>
            <span>{t('app.public.store_cart.checkout_products_COUNT', { COUNT: cart?.order_items_attributes.length })}</span>
            <div className="list">
              <p>{t('app.public.store_cart.checkout_products_total')} <span>{FormatLib.price(OrderLib.totalBeforeOfferedAmount(cart))}</span></p>
              {OrderLib.hasOfferedItem(cart) &&
                <p className='gift'>{t('app.public.store_cart.checkout_gift_total')} <span>-{FormatLib.price(OrderLib.offeredAmount(cart))}</span></p>
              }
              {cart.coupon &&
                <p>{t('app.public.store_cart.checkout_coupon')} <span>-{FormatLib.price(OrderLib.couponAmount(cart))}</span></p>
              }
            </div>
            <p className='total'>{t('app.public.store_cart.checkout_total')} <span>{FormatLib.price(OrderLib.paidTotal(cart))}</span></p>
          </div>
          <FabButton className='checkout-btn' onClick={checkout}>
            {t('app.public.store_cart.checkout')}
          </FabButton>
        </>}
      </aside>

      {cart && !cartIsEmpty() && cart.user && <div>
        <PaymentModal isOpen={paymentModal}
          toggleModal={togglePaymentModal}
          afterSuccess={handlePaymentSuccess}
          onError={onError}
          cart={{ customer_id: cart.user.id, items: [], payment_method: PaymentMethod.Card }}
          order={cart}
          operator={currentUser}
          customer={cart.user as User}
          updateCart={() => 'dont need update shopping cart'} />
      </div>}
    </div>
  );
};

const StoreCartWrapper: React.FC<StoreCartProps> = (props) => {
  return (
    <Loader>
      <StoreCart {...props} />
    </Loader>
  );
};

Application.Components.component('storeCart', react2angular(StoreCartWrapper, ['onSuccess', 'onError', 'currentUser', 'userLogin']));
