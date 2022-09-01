import React from 'react';
import { useTranslation } from 'react-i18next';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import noImage from '../../../../images/no_image.png';

declare const Application: IApplication;

interface ShowOrderProps {
  orderRef: string,
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}

/**
 * This component shows an order details
 */
export const ShowOrder: React.FC<ShowOrderProps> = ({ orderRef, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

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
          <a href={''}
            target='_blank'
            className='fab-button is-black'
            rel='noreferrer'>
            {t('app.admin.store.show_order.see_invoice')}
          </a>
        </div>
      </header>

      <div className="client-info">
        <label>{t('app.admin.store.show_order.client')}</label>
        <div className="content">
          <div className='group'>
            <span>{t('app.admin.store.show_order.client')}</span>
            <p>order.user.name</p>
          </div>
          <div className='group'>
            <span>{t('app.admin.store.show_order.created_at')}</span>
            <p>order.created_at</p>
          </div>
          <div className='group'>
            <span>{t('app.admin.store.show_order.last_update')}</span>
            <p>order.???</p>
          </div>
          <span className={`order-status ${statusColor('error')}`}>order.state</span>
        </div>
      </div>

      <div className="cart">
        <label>{t('app.admin.store.show_order.cart')}</label>
        <div>
          {/* loop sur les articles du panier */}
          <article className='store-cart-list-item'>
            <div className='picture'>
              <img alt=''src={noImage} />
            </div>
            <div className="ref">
              <span>{t('app.admin.store.show_order.reference_short')} orderable_id?</span>
              <p>o.orderable_name</p>
            </div>
            <div className="actions">
              <div className='price'>
                <p>o.amount</p>
                <span>/ {t('app.admin.store.show_order.unit')}</span>
              </div>

              <span className="count">o.quantity</span>

              <div className='total'>
                <span>{t('app.admin.store.show_order.item_total')}</span>
                <p>o.quantity * o.amount</p>
              </div>
            </div>
          </article>
        </div>
      </div>

      <div className="group">
        <div className="payment-info">
          <label>{t('app.admin.store.show_order.payment_informations')}</label>
          <p>Lorem ipsum dolor sit amet consectetur adipisicing elit. Ipsum rerum commodi quaerat possimus! Odit, harum.</p>
        </div>
        <div className="amount">
          <label>{t('app.admin.store.show_order.amount')}</label>
          <p>{t('app.admin.store.show_order.products_total')}<span>order.amount</span></p>
          <p className='gift'>{t('app.admin.store.show_order.gift_total')}<span>-order.amount</span></p>
          <p>{t('app.admin.store.show_order.coupon')}<span>order.amount</span></p>
          <p className='total'>{t('app.admin.store.show_order.total')} <span>order.total</span></p>
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

Application.Components.component('showOrder', react2angular(ShowOrderWrapper, ['orderRef', 'onError', 'onSuccess']));
