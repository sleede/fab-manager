import React from 'react';
import { useTranslation } from 'react-i18next';
import { Order } from '../../models/order';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';
import { User } from '../../models/user';
import { FabStateLabel } from '../base/fab-state-label';
import OrderLib from '../../lib/order';

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
  const showOrder = (order: Order) => {
    isPrivileged()
      ? window.location.href = `/#!/admin/store/orders/${order.id}`
      : window.location.href = `/#!/dashboard/orders/${order.id}`;
  };

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (currentUser?.role === 'admin' || currentUser?.role === 'manager');
  };

  return (
    <div className='order-item'>
      <p className="ref">{order.reference}</p>
      <div>
        <FabStateLabel status={OrderLib.statusColor(order)} background>
          {t(`app.shared.store.order_item.state.${OrderLib.statusText(order)}`)}
        </FabStateLabel>
      </div>
      {isPrivileged() &&
        <div className='client'>
          <span>{t('app.shared.store.order_item.client')}</span>
          <p>{order?.user?.name || ''}</p>
        </div>
      }
      <p className="date">{FormatLib.date(order.created_at)}</p>
      <div className='price'>
        <span>{t('app.shared.store.order_item.total')}</span>
        <p>{FormatLib.price(order.state === 'cart' ? order.total : order.paid_total)}</p>
      </div>
      <FabButton onClick={() => showOrder(order)} icon={<i className="fas fa-eye" />} className="is-black" />
    </div>
  );
};
