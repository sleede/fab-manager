import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { IApplication } from '../../models/application';
import { User } from '../../models/user';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import noImage from '../../../../images/no_image.png';
import { FabStateLabel } from '../base/fab-state-label';
import Select from 'react-select';
import OrderAPI from '../../api/order';
import { Order } from '../../models/order';
import FormatLib from '../../lib/format';
import OrderLib from '../../lib/order';

declare const Application: IApplication;

interface ShowOrderProps {
  orderId: string,
  currentUser?: User,
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}
/**
* Option format, expected by react-select
* @see https://github.com/JedWatson/react-select
*/
type selectOption = { value: number, label: string };

/**
 * This component shows an order details
 */
// TODO: delete next eslint disable
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const ShowOrder: React.FC<ShowOrderProps> = ({ orderId, currentUser, onError, onSuccess }) => {
  const { t } = useTranslation('shared');

  const [order, setOrder] = useState<Order>();

  useEffect(() => {
    OrderAPI.get(orderId).then(data => {
      setOrder(data);
    });
  }, []);

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (currentUser?.role === 'admin' || currentUser?.role === 'manager');
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.shared.store.show_order.state.error') },
      { value: 1, label: t('app.shared.store.show_order.state.canceled') },
      { value: 2, label: t('app.shared.store.show_order.state.pending') },
      { value: 3, label: t('app.shared.store.show_order.state.under_preparation') },
      { value: 4, label: t('app.shared.store.show_order.state.paid') },
      { value: 5, label: t('app.shared.store.show_order.state.ready') },
      { value: 6, label: t('app.shared.store.show_order.state.collected') },
      { value: 7, label: t('app.shared.store.show_order.state.refunded') }
    ];
  };

  /**
   * Callback after selecting an action
   */
  const handleAction = (action: selectOption) => {
    console.log('Action:', action);
  };

  // Styles the React-select component
  const customStyles = {
    control: base => ({
      ...base,
      width: '20ch',
      backgroundColor: 'transparent'
    }),
    indicatorSeparator: () => ({
      display: 'none'
    })
  };

  /**
   * Returns order's payment info
   */
  const paymentInfo = (): string => {
    let paymentVerbose = '';
    if (order.payment_method === 'card') {
      paymentVerbose = t('app.shared.store.show_order.payment.settlement_by_debit_card');
    } else if (order.payment_method === 'wallet') {
      paymentVerbose = t('app.shared.store.show_order.payment.settlement_by_wallet');
    } else {
      paymentVerbose = t('app.shared.store.show_order.payment.settlement_done_at_the_reception');
    }
    paymentVerbose += ' ' + t('app.shared.store.show_order.payment.on_DATE_at_TIME', {
      DATE: FormatLib.date(order.payment_date),
      TIME: FormatLib.time(order.payment_date)
    });
    if (order.payment_method !== 'wallet') {
      paymentVerbose += ' ' + t('app.shared.store.show_order.payment.for_an_amount_of_AMOUNT', { AMOUNT: FormatLib.price(order.paid_total) });
    }
    if (order.wallet_amount) {
      if (order.payment_method === 'wallet') {
        paymentVerbose += ' ' + t('app.shared.store.show_order.payment.for_an_amount_of_AMOUNT', { AMOUNT: FormatLib.price(order.wallet_amount) });
      } else {
        paymentVerbose += ' ' + t('app.shared.store.show_order.payment.and') + ' ' + t('app.shared.store.show_order.payment.by_wallet') + ' ' +
                                 t('app.shared.store.show_order.payment.for_an_amount_of_AMOUNT', { AMOUNT: FormatLib.price(order.wallet_amount) });
      }
    }
    return paymentVerbose;
  };

  if (!order) {
    return null;
  }

  return (
    <div className='show-order'>
      <header>
        <h2>[{order.reference}]</h2>
        <div className="grpBtn">
          {isPrivileged() &&
            <Select
              options={buildOptions()}
              onChange={option => handleAction(option)}
              styles={customStyles}
            />
          }
          {order?.invoice_id && (
            <a href={`/api/invoices/${order?.invoice_id}/download`}
              target='_blank'
              className='fab-button is-black'
              rel='noreferrer'>
              {t('app.shared.store.show_order.see_invoice')}
            </a>
          )}
        </div>
      </header>

      <div className="client-info">
        <label>{t('app.shared.store.show_order.tracking')}</label>
        <div className="content">
          {isPrivileged() && order.user &&
            <div className='group'>
              <span>{t('app.shared.store.show_order.client')}</span>
              <p>order.user.name</p>
            </div>
          }
          <div className='group'>
            <span>{t('app.shared.store.show_order.created_at')}</span>
            <p>{FormatLib.date(order.created_at)}</p>
          </div>
          <div className='group'>
            <span>{t('app.shared.store.show_order.last_update')}</span>
            <p>{FormatLib.date(order.updated_at)}</p>
          </div>
          <FabStateLabel status={OrderLib.statusColor(order)} background>
            {t(`app.shared.store.show_order.state.${OrderLib.statusText(order)}`)}
          </FabStateLabel>
        </div>
      </div>

      <div className="cart">
        <label>{t('app.shared.store.show_order.cart')}</label>
        <div>
          {order.order_items_attributes.map(item => (
            <article className='store-cart-list-item' key={item.id}>
              <div className='picture'>
                <img alt=''src={item.orderable_main_image_url || noImage} />
              </div>
              <div className="ref">
                <span>{t('app.shared.store.show_order.reference_short')}</span>
                <p>{item.orderable_name}</p>
              </div>
              <div className="actions">
                <div className='price'>
                  <p>{FormatLib.price(item.amount)}</p>
                  <span>/ {t('app.shared.store.show_order.unit')}</span>
                </div>

                <span className="count">{item.quantity}</span>

                <div className='total'>
                  <span>{t('app.shared.store.show_order.item_total')}</span>
                  <p>{FormatLib.price(OrderLib.itemAmount(item))}</p>
                </div>
              </div>
            </article>
          ))}
        </div>
      </div>

      <div className="subgrid">
        <div className="payment-info">
          <label>{t('app.shared.store.show_order.payment_informations')}</label>
          {order.invoice_id && <p>{paymentInfo()}</p>}
        </div>
        <div className="amount">
          <label>{t('app.shared.store.show_order.amount')}</label>
          <p>{t('app.shared.store.show_order.products_total')}<span>{FormatLib.price(OrderLib.totalBeforeOfferedAmount(order))}</span></p>
          {OrderLib.hasOfferedItem(order) &&
            <p className='gift'>{t('app.shared.store.show_order.gift_total')}<span>-{FormatLib.price(OrderLib.offeredAmount(order))}</span></p>
          }
          {order.coupon &&
            <p>{t('app.shared.store.show_order.coupon')}<span>-{FormatLib.price(OrderLib.couponAmount(order))}</span></p>
          }
          <p className='total'>{t('app.shared.store.show_order.cart_total')} <span>{FormatLib.price(OrderLib.paidTotal(order))}</span></p>
        </div>
      </div>
    </div>
  );
};

const ShowOrderWrapper: React.FC<ShowOrderProps> = (props) => {
  return (
    <Loader>
      <ShowOrder {...props} />
    </Loader>
  );
};

Application.Components.component('showOrder', react2angular(ShowOrderWrapper, ['orderId', 'currentUser', 'onError', 'onSuccess']));
