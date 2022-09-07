import React, { useState, useEffect } from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import { StoreListHeader } from './store-list-header';
import { AccordionItem } from './accordion-item';
import { OrderItem } from './order-item';
import { MemberSelect } from '../user/member-select';
import { User } from '../../models/user';

declare const Application: IApplication;

interface OrdersProps {
  currentUser?: User,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}
/**
* Option format, expected by react-select
* @see https://github.com/JedWatson/react-select
*/
type selectOption = { value: number, label: string };

/**
* Option format, expected by checklist
*/
type checklistOption = { value: number, label: string };

/**
 * Admin list of orders
 */
// TODO: delete next eslint disable
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const Orders: React.FC<OrdersProps> = ({ currentUser, onSuccess, onError }) => {
  console.log('currentUser: ', currentUser);
  const { t } = useTranslation('admin');

  const [filters, setFilters] = useImmer<Filters>(initFilters);
  const [clearFilters, setClearFilters] = useState<boolean>(false);
  const [accordion, setAccordion] = useState({});

  useEffect(() => {
    applyFilters();
    setClearFilters(false);
  }, [clearFilters]);

  /**
   * Create a new order
   */
  const newOrder = () => {
    console.log('Create new order');
  };

  const statusOptions: checklistOption[] = [
    { value: 0, label: t('app.admin.store.orders.status.error') },
    { value: 1, label: t('app.admin.store.orders.status.canceled') },
    { value: 2, label: t('app.admin.store.orders.status.pending') },
    { value: 3, label: t('app.admin.store.orders.status.under_preparation') },
    { value: 4, label: t('app.admin.store.orders.status.paid') },
    { value: 5, label: t('app.admin.store.orders.status.ready') },
    { value: 6, label: t('app.admin.store.orders.status.collected') },
    { value: 7, label: t('app.admin.store.orders.status.refunded') }
  ];

  /**
   * Apply filters
   */
  const applyFilters = () => {
    console.log('Apply filters:', filters);
  };

  /**
   * Clear filters
   */
  const clearAllFilters = () => {
    setFilters(initFilters);
    setClearFilters(true);
    console.log('Clear all filters');
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.admin.store.orders.sort.newest') },
      { value: 1, label: t('app.admin.store.orders.sort.oldest') }
    ];
  };
  /**
   * Display option: sorting
   */
  const handleSorting = (option: selectOption) => {
    console.log('Sort option:', option);
  };

  /**
   * Filter: by status
   */
  const handleSelectStatus = (s: checklistOption, checked) => {
    const list = [...filters.status];
    checked
      ? list.push(s)
      : list.splice(list.indexOf(s), 1);
    setFilters(draft => {
      return { ...draft, status: list };
    });
  };

  /**
   * Filter: by member
   */
  const handleSelectMember = (userId: number) => {
    setFilters(draft => {
      return { ...draft, memberId: userId };
    });
  };

  /**
   * Open/close accordion items
   */
  const handleAccordion = (id, state) => {
    setAccordion({ ...accordion, [id]: state });
  };

  return (
    <div className='orders'>
      <header>
        <h2>{t('app.admin.store.orders.heading')}</h2>
        {false &&
          <div className='grpBtn'>
            <FabButton className="main-action-btn" onClick={newOrder}>{t('app.admin.store.orders.create_order')}</FabButton>
          </div>
        }
      </header>

      <div className="store-filters">
        <header>
          <h3>{t('app.admin.store.orders.filter')}</h3>
          <div className='grpBtn'>
            <FabButton onClick={clearAllFilters} className="is-black">{t('app.admin.store.orders.filter_clear')}</FabButton>
          </div>
        </header>
        <div className="accordion">
          <AccordionItem id={0}
            isOpen={accordion[0]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_ref')}
          >
            <div className='content'>
              <div className="group">
                <input type="text" />
                <FabButton onClick={applyFilters} className="is-info">{t('app.admin.store.orders.filter_apply')}</FabButton>
              </div>
            </div>
          </AccordionItem>
          <AccordionItem id={1}
            isOpen={accordion[1]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_status')}
          >
            <div className='content'>
              <div className="group u-scrollbar">
                {statusOptions.map(s => (
                  <label key={s.value}>
                    <input type="checkbox" checked={filters.status.some(o => o.label === s.label)} onChange={(event) => handleSelectStatus(s, event.target.checked)} />
                    <p>{s.label}</p>
                  </label>
                ))}
              </div>
              <FabButton onClick={applyFilters} className="is-info">{t('app.admin.store.orders.filter_apply')}</FabButton>
            </div>
          </AccordionItem>
          <AccordionItem id={2}
            isOpen={accordion[2]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_client')}
          >
            <div className='content'>
              <div className="group">
                <MemberSelect noHeader onSelected={handleSelectMember} />
                <FabButton onClick={applyFilters} className="is-info">{t('app.admin.store.orders.filter_apply')}</FabButton>
              </div>
            </div>
          </AccordionItem>
        </div>
      </div>

      <div className="store-list">
        <StoreListHeader
          productsCount={0}
          selectOptions={buildOptions()}
          onSelectOptionsChange={handleSorting}
        />
        <div className="orders-list">
          <OrderItem currentUser={currentUser} />
        </div>
      </div>
    </div>
  );
};

const OrdersWrapper: React.FC<OrdersProps> = (props) => {
  return (
    <Loader>
      <Orders {...props} />
    </Loader>
  );
};

Application.Components.component('orders', react2angular(OrdersWrapper, ['currentUser', 'onSuccess', 'onError']));

interface Filters {
  reference: string,
  status: checklistOption[],
  memberId: number
}

const initFilters: Filters = {
  reference: '',
  status: [],
  memberId: null
};
