import React from 'react';
import { useTranslation } from 'react-i18next';
import { Order } from '../../models/order';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';
import { User } from '../../models/user';
import { FabStateLabel } from '../base/fab-state-label';

interface OrderItemProps {
  order?: Order,
  currentUser?: User
}

/**
 * List item for an order
 */
export const OrderItem: React.FC<OrderItemProps> = ({ order, currentUser }) => {
  const { t } = useTranslation('shared');
  /**
   * Go to order page
   */
  const showOrder = (ref: string) => {
    isPrivileged()
      ? window.location.href = `/#!/admin/store/o/${ref}`
      : window.location.href = `/#!/store/o/${ref}`;
  };

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (currentUser?.role === 'admin' || currentUser?.role === 'manager');
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
    <div className='order-item'>
      <p className="ref">order.ref</p>
      <div>
        <FabStateLabel status={statusColor('pending')} background>
          order.state
        </FabStateLabel>
      </div>
      {isPrivileged() &&
        <div className='client'>
          <span>{t('app.shared.store.order_item.client')}</span>
          <p>order.user.name</p>
        </div>
      }
      <p className="date">order.created_at</p>
      <div className='price'>
        <span>{t('app.shared.store.order_item.total')}</span>
        <p>{FormatLib.price(order?.total)}</p>
      </div>
      <FabButton onClick={() => showOrder('orderRef')} icon={<i className="fas fa-eye" />} className="is-black" />
    </div>
  );
};
