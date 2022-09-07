import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { StoreListHeader } from './store-list-header';

declare const Application: IApplication;

interface OrdersDashboardProps {
  onError: (message: string) => void
}
/**
* Option format, expected by react-select
* @see https://github.com/JedWatson/react-select
*/
type selectOption = { value: number, label: string };

/**
 * This component shows a list of all orders from the store for the current user
 */
// TODO: delete next eslint disable
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const OrdersDashboard: React.FC<OrdersDashboardProps> = ({ onError }) => {
  const { t } = useTranslation('public');

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.public.store.orders_dashboard.sort.newest') },
      { value: 1, label: t('app.public.store.orders_dashboard.sort.oldest') }
    ];
  };
  /**
   * Display option: sorting
   */
  const handleSorting = (option: selectOption) => {
    console.log('Sort option:', option);
  };

  return (
    <section className="orders-dashboard">
      <header>
        <h2>{t('app.public.store.orders_dashboard.heading')}</h2>
      </header>

      <div className="store-list">
        <StoreListHeader
          productsCount={0}
          selectOptions={buildOptions()}
          onSelectOptionsChange={handleSorting}
        />
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

Application.Components.component('ordersDashboard', react2angular(OrdersDashboardWrapper, ['onError']));
