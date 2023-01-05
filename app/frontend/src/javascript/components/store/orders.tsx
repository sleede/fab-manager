import { useState, useEffect } from 'react';
import * as React from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { useForm } from 'react-hook-form';
import { FabButton } from '../base/fab-button';
import { StoreListHeader } from './store-list-header';
import { AccordionItem } from '../base/accordion-item';
import { OrderItem } from './order-item';
import { MemberSelect } from '../user/member-select';
import { User } from '../../models/user';
import { FormInput } from '../form/form-input';
import OrderAPI from '../../api/order';
import { Order, OrderIndexFilter, OrderSortOption } from '../../models/order';
import { FabPagination } from '../base/fab-pagination';
import { CaretDoubleUp, X } from 'phosphor-react';
import { ChecklistOption, SelectOption } from '../../models/select';

declare const Application: IApplication;

interface OrdersProps {
  currentUser?: User,
  onError: (message: string) => void,
}

const initFilters: OrderIndexFilter = {
  reference: '',
  states: [],
  page: 1,
  sort: 'created_at-desc'
};

const FablabOrdersFilters = 'FablabOrdersFilters';

/**
 * Admin list of orders
 */
const Orders: React.FC<OrdersProps> = ({ currentUser, onError }) => {
  const { t } = useTranslation('admin');

  const { register, setValue } = useForm();

  const [orders, setOrders] = useState<Array<Order>>([]);
  const [filters, setFilters] = useImmer<OrderIndexFilter>(window[FablabOrdersFilters] || initFilters);
  const [accordion, setAccordion] = useState({});
  const [filtersPanel, setFiltersPanel] = useState<boolean>(true);
  const [pageCount, setPageCount] = useState<number>(0);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [reference, setReference] = useState<string>(filters.reference);
  const [states, setStates] = useState<Array<string>>(filters.states);
  const [user, setUser] = useState<{ id: number, name?: string }>(filters.user);
  const [periodFrom, setPeriodFrom] = useState<string>(filters.period_from);
  const [periodTo, setPeriodTo] = useState<string>(filters.period_to);

  useEffect(() => {
    window[FablabOrdersFilters] = filters;
    OrderAPI.index(filters).then(res => {
      setPageCount(res.total_pages);
      setTotalCount(res.total_count);
      setOrders(res.data);
    }).catch(onError);
  }, [filters]);

  const statusOptions: ChecklistOption<string>[] = [
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
            draft.user = user;
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
   * Clear filter by type
   */
  const removeFilter = (filterType: string, state?: string) => {
    return () => {
      setFilters(draft => {
        draft.page = 1;
        draft.sort = 'created_at-desc';
        switch (filterType) {
          case 'reference':
            draft.reference = '';
            setReference('');
            break;
          case 'states': {
            const s = [...draft.states];
            s.splice(states.indexOf(state), 1);
            setStates(s);
            draft.states = s;
            break;
          }
          case 'user':
            delete draft.user_id;
            delete draft.user;
            setUser(null);
            break;
          case 'period':
            draft.period_from = '';
            draft.period_to = '';
            setPeriodFrom(null);
            setPeriodTo(null);
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
  const buildOptions = (): Array<SelectOption<OrderSortOption>> => {
    return [
      { value: 'created_at-desc', label: t('app.admin.store.orders.sort.newest') },
      { value: 'created_at-asc', label: t('app.admin.store.orders.sort.oldest') }
    ];
  };

  /**
   * Display option: sorting
   */
  const handleSorting = (option: SelectOption<OrderSortOption>) => {
    setFilters(draft => {
      draft.sort = option.value;
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
  const handleSelectStatus = (s: ChecklistOption<string>, checked: boolean) => {
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
      </header>

      <aside className={`store-filters ${filtersPanel ? '' : 'collapsed'}`}>
        <header>
          <h3>{t('app.admin.store.orders.filter')}</h3>
          <div className='grpBtn'>
            <FabButton onClick={clearAllFilters} className="is-black">{t('app.admin.store.orders.filter_clear')}</FabButton>
            <CaretDoubleUp className='filters-toggle' size={16} weight="bold" onClick={() => setFiltersPanel(!filtersPanel)} />
          </div>
        </header>
        <div className="grp accordion">
          <AccordionItem id={0}
            isOpen={accordion[0]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_ref')}
          >
            <div className='content'>
              <div className="group">
                <input type="text" value={reference} onChange={(event) => handleReferenceChanged(event.target.value)}/>
                <FabButton onClick={applyFilters('reference')} className="is-secondary">{t('app.admin.store.orders.filter_apply')}</FabButton>
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
              <FabButton onClick={applyFilters('states')} className="is-secondary">{t('app.admin.store.orders.filter_apply')}</FabButton>
            </div>
          </AccordionItem>
          <AccordionItem id={2}
            isOpen={accordion[2]}
            onChange={handleAccordion}
            label={t('app.admin.store.orders.filter_client')}
          >
            <div className='content'>
              <div className="group">
                <MemberSelect noHeader value={user as User} onSelected={handleSelectMember} />
                <FabButton onClick={applyFilters('user')} className="is-secondary">{t('app.admin.store.orders.filter_apply')}</FabButton>
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
                <div className="range">
                  <FormInput id="period_from"
                             label={t('app.admin.store.orders.filter_period_from')}
                             register={register}
                             onChange={handlePeriodChanged('period_from')}
                             defaultValue={periodFrom}
                             type="date" />
                  <FormInput id="period_to"
                             label={t('app.admin.store.orders.filter_period_to')}
                             register={register}
                             onChange={handlePeriodChanged('period_to')}
                             defaultValue={periodTo}
                             type="date" />
                </div>
                <FabButton onClick={applyFilters('period')} className="is-secondary">{t('app.admin.store.orders.filter_apply')}</FabButton>
              </div>
            </div>
          </AccordionItem>
        </div>
      </aside>

      <div className="store-list">
        <StoreListHeader
          productsCount={totalCount}
          selectOptions={buildOptions()}
          selectValue={filters.sort}
          onSelectOptionsChange={handleSorting}
        />
        <div className='features'>
          {filters.reference && <div className='features-item'>
            <p>{filters.reference}</p>
            <button onClick={removeFilter('reference')}><X size={16} weight="light" /></button>
          </div>}
          {filters.states?.map((status, index) => (
            <div key={index} className='features-item'>
              <p>{t(`app.admin.store.orders.state.${status}`)}</p>
              <button onClick={removeFilter('states', status)}><X size={16} weight="light" /></button>
            </div>
          ))}
          {filters.user_id > 0 && <div className='features-item'>
            <p>{user?.name}</p>
            <button onClick={removeFilter('user')}><X size={16} weight="light" /></button>
          </div>}
          {filters.period_from && <div className='features-item'>
            <p>{filters.period_from} {'>'} {filters.period_to}</p>
            <button onClick={removeFilter('period')}><X size={16} weight="light" /></button>
          </div>}
        </div>

        <div className="orders-list">
          {orders.map(order => (
            <OrderItem key={order.id} order={order} currentUser={currentUser} />
          ))}
        </div>
        {pageCount > 1 &&
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

Application.Components.component('orders', react2angular(OrdersWrapper, ['currentUser', 'onError']));
