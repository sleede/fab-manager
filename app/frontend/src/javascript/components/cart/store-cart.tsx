import { useState, useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import useCart from '../../hooks/use-cart';
import FormatLib from '../../lib/format';
import CartAPI from '../../api/cart';
import { User } from '../../models/user';
import { PaymentModal } from '../payment/stripe/payment-modal';
import { PaymentMethod } from '../../models/payment';
import { Order, OrderErrors } from '../../models/order';
import { MemberSelect } from '../user/member-select';
import { CouponInput } from '../coupon/coupon-input';
import { Coupon } from '../../models/coupon';
import noImage from '../../../../images/no_image.png';
import Switch from 'react-switch';
import OrderLib from '../../lib/order';
import { CaretDown, CaretUp } from 'phosphor-react';
import _ from 'lodash';
import OrderAPI from '../../api/order';

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
   * Remove the product from cart
   */
  const removeProductFromCart = (item) => {
    return (e: React.BaseSyntheticEvent) => {
      e.preventDefault();
      e.stopPropagation();
      const errors = getItemErrors(item);
      if (errors.length === 1 && errors[0].error === 'not_found') {
        reloadCart().catch(onError);
      } else {
        CartAPI.removeItem(cart, item.orderable_id).then(data => {
          setCart(data);
        }).catch(onError);
      }
    };
  };

  /**
   * Change product quantity
   */
  const changeProductQuantity = (e: React.BaseSyntheticEvent, item) => {
    CartAPI.setQuantity(cart, item.orderable_id, e.target.value)
      .then(data => {
        setCart(data);
      })
      .catch(() => onError(t('app.public.store_cart.stock_limit')));
  };

  /**
   * Increment/decrement product quantity
   */
  const increaseOrDecreaseProductQuantity = (item, direction: 'up' | 'down') => {
    CartAPI.setQuantity(cart, item.orderable_id, direction === 'up' ? item.quantity + 1 : item.quantity - 1)
      .then(data => {
        setCart(data);
      })
      .catch(() => onError(t('app.public.store_cart.stock_limit')));
  };

  /**
   * Refresh product amount
   */
  const refreshItem = (item) => {
    return (e: React.BaseSyntheticEvent) => {
      e.preventDefault();
      e.stopPropagation();
      CartAPI.refreshItem(cart, item.orderable_id).then(data => {
        setCart(data);
      }).catch(onError);
    };
  };

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
   * get givean item's error
   */
  const getItemErrors = (item) => {
    if (!cartErrors) return [];
    const errors = _.find(cartErrors.details, (e) => e.item_id === item.id);
    return errors?.errors || [{ error: 'not_found' }];
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
   * Change cart's customer by admin/manger
   */
  const handleChangeMember = (user: User): void => {
    // if the selected user is the operator, he cannot offer products to himself
    if (user.id === currentUser.id && cart.order_items_attributes.filter(item => item.is_offered).length > 0) {
      Promise.all(cart.order_items_attributes.filter(item => item.is_offered).map(item => {
        return CartAPI.setOffer(cart, item.orderable_id, false);
      })).then((data) => setCart({ ...data[data.length - 1], user: { id: user.id, role: user.role } }));
    } else {
      setCart({ ...cart, user: { id: user.id, role: user.role } });
    }
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
   * Toggle product offer
   */
  const toggleProductOffer = (item) => {
    return (checked: boolean) => {
      CartAPI.setOffer(cart, item.orderable_id, checked).then(data => {
        setCart(data);
      }).catch(e => {
        if (e.match(/code 403/)) {
          onError(t('app.public.store_cart.errors.unauthorized_offering_product'));
        } else {
          onError(e);
        }
      });
    };
  };

  /**
   * Apply coupon to current cart
   */
  const applyCoupon = (coupon?: Coupon): void => {
    if (coupon !== cart.coupon) {
      setCart({ ...cart, coupon });
    }
  };

  /**
   * Show item error
   */
  const itemError = (item, error) => {
    if (error.error === 'is_active' || error.error === 'not_found') {
      return <div className='error'><p>{t('app.public.store_cart.errors.product_not_found')}</p></div>;
    }
    if (error.error === 'stock' && error.value === 0) {
      return <div className='error'><p>{t('app.public.store_cart.errors.out_of_stock')}</p></div>;
    }
    if (error.error === 'stock' && error.value > 0) {
      return <div className='error'><p>{t('app.public.store_cart.errors.stock_limit_QUANTITY', { QUANTITY: error.value })}</p></div>;
    }
    if (error.error === 'quantity_min') {
      return <div className='error'><p>{t('app.public.store_cart.errors.quantity_min_QUANTITY', { QUANTITY: error.value })}</p></div>;
    }
    if (error.error === 'amount') {
      return <div className='error'>
        <p>{t('app.public.store_cart.errors.price_changed_PRICE', { PRICE: `${FormatLib.price(error.value)} / ${t('app.public.store_cart.unit')}` })}</p>
        <span className='refresh-btn' onClick={refreshItem(item)}>{t('app.public.store_cart.update_item')}</span>
        </div>;
    }
  };

  return (
    <div className='store-cart'>
      <div className="store-cart-list">
        {cart && cartIsEmpty() && <p>{t('app.public.store_cart.cart_is_empty')}</p>}
        {cart && cart.order_items_attributes.map(item => (
          <article key={item.id} className={`store-cart-list-item ${getItemErrors(item).length > 0 ? 'error' : ''}`}>
            <div className='picture'>
              <img alt='' src={item.orderable_main_image_url || noImage} />
            </div>
            <div className="ref">
              <span>{t('app.public.store_cart.reference_short')} {item.orderable_ref || ''}</span>
              <p><a className="text-black" href={`/#!/store/p/${item.orderable_slug}`}>{item.orderable_name}</a></p>
              {item.quantity_min > 1 &&
                <span className='min'>{t('app.public.store_cart.minimum_purchase')}{item.quantity_min}</span>
              }
              {getItemErrors(item).map(e => {
                return itemError(item, e);
              })}
            </div>
            <div className="actions">
              <div className='price'>
                <p>{FormatLib.price(item.amount)}</p>
                <span>/ {t('app.public.store_cart.unit')}</span>
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
              <div className='total'>
                <span>{t('app.public.store_cart.total')}</span>
                <p>{FormatLib.price(OrderLib.itemAmount(item))}</p>
              </div>
              <FabButton className="main-action-btn" onClick={removeProductFromCart(item)}>
                <i className="fa fa-trash" />
              </FabButton>
            </div>
            {isPrivileged() &&
              <div className='offer'>
                <label>
                  <span>{t('app.public.store_cart.offer_product')}</span>
                  <Switch
                  checked={item.is_offered || false}
                  onChange={toggleProductOffer(item)}
                  width={40}
                  height={19}
                  uncheckedIcon={false}
                  checkedIcon={false}
                  handleDiameter={15} />
                </label>
              </div>
            }
          </article>
        ))}
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
