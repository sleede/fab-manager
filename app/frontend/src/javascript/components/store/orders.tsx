import React, { useState, useEffect } from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { useForm } from 'react-hook-form';
import { FabButton } from '../base/fab-button';
import { StoreListHeader } from './store-list-header';
import { AccordionItem } from './accordion-item';
import { OrderItem } from './order-item';
import { MemberSelect } from '../user/member-select';
import { User } from '../../models/user';
import { FormInput } from '../form/form-input';
import OrderAPI from '../../api/order';
import { Order, OrderIndexFilter } from '../../models/order';
import { FabPagination } from '../base/fab-pagination';
import { TDateISO } from '../../typings/date-iso';

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
type checklistOption = { value: string, label: string };

/**
 * Admin list of orders
 */
// TODO: delete next eslint disable
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const Orders: React.FC<OrdersProps> = ({ currentUser, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const { register, getValues, setValue } = useForm();

  const [orders, setOrders] = useState<Array<Order>>([]);
  const [filters, setFilters] = useImmer<OrderIndexFilter>(initFilters);
  const [accordion, setAccordion] = useState({});
  const [pageCount, setPageCount] = useState<number>(0);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [reference, setReference] = useState<string>(filters.reference);
  const [states, setStates] = useState<Array<string>>(filters.states);
  const [user, setUser] = useState<User>();
  const [periodFrom, setPeriodFrom] = useState<string>();
  const [periodTo, setPeriodTo] = useState<string>();

  useEffect(() => {
    OrderAPI.index(filters).then(res => {
      setPageCount(res.total_pages);
      setTotalCount(res.total_count);
      setOrders(res.data);
    }).catch(onError);
  }, [filters]);

  /**
   * Create a new order
   */
  const newOrder = () => {
    console.log('Create new order');
  };

  const statusOptions: checklistOption[] = [
    { value: 'cart', label: t('app.admin.store.orders.state.cart') },
    { value: 'paid', label: t('app.admin.store.orders.state.paid') },
    { value: 'payment_failed', label: t('app.admin.store.orders.state.payment_failed') },
    { value: 'in_progress', label: t('app.admin.store.orders.state.in_progress') },
    { value: 'ready', label: t('app.admin.store.orders.state.ready') },
    { value: 'canceled', label: t('app.admin.store.orders.state.canceled') }
  ];

  /**
   * Apply filters
   */
  const applyFilters = (filterType: string) => {
    return () => {
      setFilters(draft => {
        switch (filterType) {
          case 'reference':
            draft.reference = reference;
            break;
          case 'states':
            draft.states = states;
            break;
          case 'user':
            draft.user_id = user.id;
            break;
          case 'period':
            if (periodFrom && periodTo) {
              draft.period_from = periodFrom;
              draft.period_to = periodTo;
            } else {
              draft.period_from = '';
              draft.period_to = '';
            }
            break;
          default:
        }
      });
    };
  };

  /**
   * Clear filters
   */
  const clearAllFilters = () => {
    setFilters(initFilters);
    setReference('');
    setStates([]);
    setUser(null);
    setPeriodFrom(null);
    setPeriodTo(null);
    setValue('period_from', '');
    setValue('period_to', '');
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
    setFilters(draft => {
      draft.sort = option.value ? 'ASC' : 'DESC';
    });
  };

  /**
   * Filter: by reference
   */
  const handleReferenceChanged = (value: string) => {
    setReference(value);
  };

  /**
   * Filter: by status
   */
  const handleSelectStatus = (s: checklistOption, checked: boolean) => {
    const list = [...states];
    checked
      ? list.push(s.value)
      : list.splice(list.indexOf(s.value), 1);
    setStates(list);
  };

  /**
   * Filter: by member
   */
  const handleSelectMember = (user: User) => {
    setUser(user);
  };

  /**
   * Filter: by period
   */
  const handlePeriodChanged = (period: string) => {
    return (event: React.ChangeEvent<HTMLInputElement>) => {
      const value = event.target.value;
      if (period === 'period_from') {
        setPeriodFrom(value);
      }
      if (period === 'period_to') {
        setPeriodTo(value);
      }
    };
  };

  /**
   * Open/close accordion items
   */
  const handleAccordion = (id, state) => {
    setAccordion({ ...accordion, [id]: state });
  };

  /**
   * Handle orders pagination
   */
  const handlePagination = (page: number) => {
    setFilters(draft => {
      draft.page = page;
    });
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
        <div>
          {filters.reference && <div>{filters.reference}</div>}
          {filters.states.length > 0 && <div>{filters.states.join(', ')}</div>}
          {filters.user_id > 0 && <div>{user?.name}</div>}
          {filters.period_from && <div>{filters.period_from} - {filters.period_to}</div>}
        </div>
        <div className="accordion">
          <AccordionItem id={0}
            isOpen={accordion[0]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_ref')}
          >
            <div className='content'>
              <div className="group">
                <input type="text" value={reference} onChange={(event) => handleReferenceChanged(event.target.value)}/>
                <FabButton onClick={applyFilters('reference')} className="is-info">{t('app.admin.store.orders.filter_apply')}</FabButton>
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
                    <input type="checkbox" checked={states.some(o => o === s.value)} onChange={(event) => handleSelectStatus(s, event.target.checked)} />
                    <p>{s.label}</p>
                  </label>
                ))}
              </div>
              <FabButton onClick={applyFilters('states')} className="is-info">{t('app.admin.store.orders.filter_apply')}</FabButton>
            </div>
          </AccordionItem>
          <AccordionItem id={2}
            isOpen={accordion[2]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_client')}
          >
            <div className='content'>
              <div className="group">
                <MemberSelect noHeader value={user} onSelected={handleSelectMember} />
                <FabButton onClick={applyFilters('user')} className="is-info">{t('app.admin.store.orders.filter_apply')}</FabButton>
              </div>
            </div>
          </AccordionItem>
          <AccordionItem id={3}
            isOpen={accordion[3]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_period')}
          >
            <div className='content'>
              <div className="group">
                <div className="period">
                  from
                  <FormInput id="period_from"
                             register={register}
                             onChange={handlePeriodChanged('period_from')}
                             type="date" />
                  to
                  <FormInput id="period_to"
                             register={register}
                             onChange={handlePeriodChanged('period_to')}
                             type="date" />
                </div>
                <FabButton onClick={applyFilters('period')} className="is-info">{t('app.admin.store.orders.filter_apply')}</FabButton>
              </div>
            </div>
          </AccordionItem>
        </div>
      </div>

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
        {orders.length > 0 &&
          <FabPagination pageCount={pageCount} currentPage={filters.page} selectPage={handlePagination} />
        }
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

const initFilters: OrderIndexFilter = {
  reference: '',
  states: [],
  page: 1,
  sort: 'DESC'
};
