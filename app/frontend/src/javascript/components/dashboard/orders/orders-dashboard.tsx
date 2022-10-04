import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../../base/loader';
import { IApplication } from '../../../models/application';
import { StoreListHeader } from '../../store/store-list-header';
import { OrderItem } from '../../store/order-item';
import { FabPagination } from '../../base/fab-pagination';
import OrderAPI from '../../../api/order';
import { Order, OrderSortOption } from '../../../models/order';
import { User } from '../../../models/user';

declare const Application: IApplication;

interface OrdersDashboardProps {
  currentUser: User,
  onError: (message: string) => void
}
/**
* Option format, expected by react-select
* @see https://github.com/JedWatson/react-select
*/
type selectOption = { value: OrderSortOption, label: string };

/**
 * This component shows a list of all orders from the store for the current user
 */
export const OrdersDashboard: React.FC<OrdersDashboardProps> = ({ currentUser, onError }) => {
  const { t } = useTranslation('public');

  const [orders, setOrders] = useState<Array<Order>>([]);
  const [pageCount, setPageCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [totalCount, setTotalCount] = useState<number>(0);

  useEffect(() => {
    OrderAPI.index({ user_id: currentUser.id }).then(res => {
      setPageCount(res.total_pages);
      setTotalCount(res.total_count);
      setOrders(res.data);
    }).catch(onError);
  }, []);

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return [
      { value: 'created_at-desc', label: t('app.public.orders_dashboard.sort.newest') },
      { value: 'created_at-asc', label: t('app.public.orders_dashboard.sort.oldest') }
    ];
  };
  /**
   * Display option: sorting
   */
  const handleSorting = (option: selectOption) => {
    OrderAPI.index({ page: 1, sort: option.value }).then(res => {
      setCurrentPage(1);
      setOrders(res.data);
      setPageCount(res.total_pages);
      setTotalCount(res.total_count);
    }).catch(onError);
  };

  /**
   * Handle orders pagination
   */
  const handlePagination = (page: number) => {
    if (page !== currentPage) {
      OrderAPI.index({ user_id: currentUser.id, page }).then(res => {
        setCurrentPage(page);
        setOrders(res.data);
        setPageCount(res.total_pages);
        setTotalCount(res.total_count);
      }).catch(onError);
    }
  };

  return (
    <section className="orders-dashboard">
      <header>
        <h2>{t('app.public.orders_dashboard.heading')}</h2>
      </header>

      <div className="store-list">
        <StoreListHeader
          productsCount={totalCount}
          selectOptions={buildOptions()}
          onSelectOptionsChange={handleSorting}
        />
        <div className="orders-list">
          {orders.map(order => (
            <OrderItem key={order.id} order={order} currentUser={currentUser} />
          ))}
        </div>
        {pageCount > 1 &&
          <FabPagination pageCount={pageCount} currentPage={currentPage} selectPage={handlePagination} />
        }
      </div>
    </section>
  );
};

const OrdersDashboardWrapper: React.FC<OrdersDashboardProps> = (props) => {
  return (
    <Loader>
      <OrdersDashboard {...props} />
    </Loader>
  );
};

Application.Components.component('ordersDashboard', react2angular(OrdersDashboardWrapper, ['onError', 'currentUser']));
