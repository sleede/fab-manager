import React from 'react';
import { useTranslation } from 'react-i18next';
import { IApplication } from '../../models/application';
import { User } from '../../models/user';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import noImage from '../../../../images/no_image.png';
import { FabStateLabel } from '../base/fab-state-label';
import Select from 'react-select';

declare const Application: IApplication;

interface ShowOrderProps {
  orderRef: string,
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
export const ShowOrder: React.FC<ShowOrderProps> = ({ orderRef, currentUser, onError, onSuccess }) => {
  const { t } = useTranslation('shared');

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
      { value: 0, label: t('app.shared.store.show_order.status.error') },
      { value: 1, label: t('app.shared.store.show_order.status.canceled') },
      { value: 2, label: t('app.shared.store.show_order.status.pending') },
      { value: 3, label: t('app.shared.store.show_order.status.under_preparation') },
      { value: 4, label: t('app.shared.store.show_order.status.paid') },
      { value: 5, label: t('app.shared.store.show_order.status.ready') },
      { value: 6, label: t('app.shared.store.show_order.status.collected') },
      { value: 7, label: t('app.shared.store.show_order.status.refunded') }
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
   * Returns a className according to the status
   */
  const statusColor = (status: string) => {
    switch (status) {
      case 'error':
        return 'error';
      case 'canceled':
        return 'canceled';
      case 'pending' || 'under_preparation':
        return 'pending';
      default:
        return 'normal';
    }
  };

  return (
    <div className='show-order'>
      <header>
        <h2>[order.ref]</h2>
        <div className="grpBtn">
          {isPrivileged() &&
            <Select
              options={buildOptions()}
              onChange={option => handleAction(option)}
              styles={customStyles}
            />
          }
          <a href={''}
            target='_blank'
            className='fab-button is-black'
            rel='noreferrer'>
            {t('app.shared.store.show_order.see_invoice')}
          </a>
        </div>
      </header>

      <div className="client-info">
        <label>{t('app.shared.store.show_order.tracking')}</label>
        <div className="content">
          {isPrivileged() &&
            <div className='group'>
              <span>{t('app.shared.store.show_order.client')}</span>
              <p>order.user.name</p>
            </div>
          }
          <div className='group'>
            <span>{t('app.shared.store.show_order.created_at')}</span>
            <p>order.created_at</p>
          </div>
          <div className='group'>
            <span>{t('app.shared.store.show_order.last_update')}</span>
            <p>order.???</p>
          </div>
          <FabStateLabel status={statusColor('error')} background>
            order.state
          </FabStateLabel>
        </div>
      </div>

      <div className="cart">
        <label>{t('app.shared.store.show_order.cart')}</label>
        <div>
          {/* loop sur les articles du panier */}
          <article className='store-cart-list-item'>
            <div className='picture'>
              <img alt=''src={noImage} />
            </div>
            <div className="ref">
              <span>{t('app.shared.store.show_order.reference_short')} orderable_id?</span>
              <p>o.orderable_name</p>
            </div>
            <div className="actions">
              <div className='price'>
                <p>o.amount</p>
                <span>/ {t('app.shared.store.show_order.unit')}</span>
              </div>

              <span className="count">o.quantity</span>

              <div className='total'>
                <span>{t('app.shared.store.show_order.item_total')}</span>
                <p>o.quantity * o.amount</p>
              </div>
            </div>
          </article>
        </div>
      </div>

      <div className="subgrid">
        <div className="payment-info">
          <label>{t('app.shared.store.show_order.payment_informations')}</label>
          <p>Lorem ipsum dolor sit amet consectetur adipisicing elit. Ipsum rerum commodi quaerat possimus! Odit, harum.</p>
        </div>
        <div className="amount">
          <label>{t('app.shared.store.show_order.amount')}</label>
          <p>{t('app.shared.store.show_order.products_total')}<span>order.amount</span></p>
          <p className='gift'>{t('app.shared.store.show_order.gift_total')}<span>-order.amount</span></p>
          <p>{t('app.shared.store.show_order.coupon')}<span>order.amount</span></p>
          <p className='total'>{t('app.shared.store.show_order.cart_total')} <span>order.total</span></p>
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

Application.Components.component('showOrder', react2angular(ShowOrderWrapper, ['orderRef', 'currentUser', 'onError', 'onSuccess']));
