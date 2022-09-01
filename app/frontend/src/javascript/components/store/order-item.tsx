import React from 'react';
import { useTranslation } from 'react-i18next';
import { Order } from '../../models/order';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';

interface OrderItemProps {
  order?: Order
  statusColor: string
}

/**
 * List item for an order
 */
export const OrderItem: React.FC<OrderItemProps> = ({ order, statusColor }) => {
  const { t } = useTranslation('admin');
  /**
   * Go to order page
   */
  const showOrder = (token: string) => {
    window.location.href = `/#!/admin/store/o/${token}`;
  };

  return (
    <div className='order-item'>
      <p className="ref">order.token</p>
      <span className={`order-status ${statusColor}`}>order.state</span>
      <div className='client'>
        <span>{t('app.admin.store.order_item.client')}</span>
        <p>order.user.name</p>
      </div>
      <p className="date">order.created_at</p>
      <div className='price'>
        <span>{t('app.admin.store.order_item.total')}</span>
        <p>{FormatLib.price(order?.total)}</p>
      </div>
      <FabButton onClick={() => showOrder('orderToken')} icon={<i className="fas fa-eye" />} className="is-black" />
    </div>
  );
};
