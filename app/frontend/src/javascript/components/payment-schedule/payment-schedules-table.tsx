import { ReactEventHandler, useState, useEffect, ReactElement } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';
import _ from 'lodash';
import { User } from '../../models/user';
import type { PaymentSchedule, PaymentScheduleItem } from '../../models/payment-schedule';
import FormatLib from '../../lib/format';
import { PaymentScheduleItemActions, TypeOnce } from './payment-schedule-item-actions';
import { StripeElements } from '../payment/stripe/stripe-elements';
import SettingAPI from '../../api/setting';
import { Setting } from '../../models/setting';

interface PaymentSchedulesTableProps {
  paymentSchedules: Array<PaymentSchedule>,
  showCustomer?: boolean,
  refreshList: () => void,
  operator: User,
  onError: (message: string) => void,
  onCardUpdateSuccess: () => void
}

/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */
const PaymentSchedulesTable: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList, operator, onError, onCardUpdateSuccess }) => {
  const { t } = useTranslation('shared');

  // for each payment schedule: are the details (all deadlines) shown or hidden?
  const [showExpanded, setShowExpanded] = useState<Map<number, boolean>>(new Map());
  // we want to display some buttons only once. This map keep track of the buttons that have been displayed.
  const [displayOnceMap] = useState<Map<TypeOnce, Map<number, number>>>(new Map([
    ['subscription-cancel', new Map()],
    ['card-update', new Map()],
    ['update-payment-mean', new Map()]
  ]));
  const [gateway, setGateway] = useState<Setting>(null);

  useEffect(() => {
    SettingAPI.get('payment_gateway')
      .then(setting => setGateway(setting))
      .catch(error => onError(error));
  }, []);

  /**
   * Check if the requested payment schedule is displayed with its deadlines (PaymentScheduleItem) or without them
   */
  const isExpanded = (paymentScheduleId: number): boolean => {
    return showExpanded.get(paymentScheduleId);
  };

  /**
   * Return the value for the CSS property 'display', for the payment schedule deadlines
   */
  const statusDisplay = (paymentScheduleId: number): string => {
    if (isExpanded(paymentScheduleId)) {
      return 'table-row';
    } else {
      return 'none';
    }
  };

  /**
   * Return the action icon for showing/hiding the deadlines
   */
  const expandCollapseIcon = (paymentScheduleId: number): JSX.Element => {
    if (isExpanded(paymentScheduleId)) {
      // eslint-disable-next-line fabmanager/component-class-named-as-component
      return <i className="fas fa-minus-square" />;
    } else {
      // eslint-disable-next-line fabmanager/component-class-named-as-component
      return <i className="fas fa-plus-square" />;
    }
  };

  /**
   * Show or hide the deadlines for the provided payment schedule, inverting their current status
   */
  const togglePaymentScheduleDetails = (paymentScheduleId: number): ReactEventHandler => {
    return (): void => {
      if (isExpanded(paymentScheduleId)) {
        setShowExpanded((prev) => new Map(prev).set(paymentScheduleId, false));
      } else {
        setShowExpanded((prev) => new Map(prev).set(paymentScheduleId, true));
      }
    };
  };

  /**
   * Return a button to download a PDF file, may be an invoice, or a payment schedule, depending or the provided parameters
   */
  const downloadScheduleButton = (id: number): JSX.Element => {
    const link = `api/payment_schedules/${id}/download`;
    return (
      // eslint-disable-next-line fabmanager/component-class-named-as-component
      <a href={link} target="_blank" className="download-button" rel="noreferrer">
        <i className="fas fa-download" />
        {t('app.shared.payment_schedules_table.download')}
      </a>
    );
  };

  /**
   * Return the human-readable string for the status of the provided deadline.
   */
  const formatState = (item: PaymentScheduleItem, schedule: PaymentSchedule): JSX.Element => {
    let res = t(`app.shared.payment_schedules_table.state_${item.state}${item.state === 'pending' ? '_' + schedule.payment_method : ''}`);
    if (item.state === 'paid') {
      const key = `app.shared.payment_schedules_table.method_${item.payment_method}`;
      res += ` (${t(key)})`;
    }
    // eslint-disable-next-line fabmanager/component-class-named-as-component
    return <span className={`state-${item.state}`}>{res}</span>;
  };

  /**
   * Refresh all payment schedules in the table
   */
  const refreshSchedulesTable = (): void => {
    refreshList();
  };

  /**
   * Return the JSX table element that list all payment schedules and allows to perform actions on them.
   */
  const renderPaymentSchedulesTable = (): ReactElement => {
    return (
      <table className="payment-schedules-table">
        <thead>
          <tr>
            <th className="w-35" />
            <th className="w-200">{t('app.shared.payment_schedules_table.schedule_num')}</th>
            <th className="w-200">{t('app.shared.payment_schedules_table.date')}</th>
            <th className="w-120">{t('app.shared.payment_schedules_table.price')}</th>
            {showCustomer && <th className="w-200">{t('app.shared.payment_schedules_table.customer')}</th>}
            <th className="w-200"/>
          </tr>
        </thead>
        <tbody>
          {paymentSchedules.map(p => <tr key={p.id}>
            <td colSpan={showCustomer ? 6 : 5}>
              <table className="schedules-table-body">
                <tbody>
                  <tr>
                    <td className="w-35 row-header" onClick={togglePaymentScheduleDetails(p.id)}>{expandCollapseIcon(p.id)}</td>
                    <td className="w-200">{p.reference}</td>
                    <td className="w-200">{FormatLib.date(_.minBy(p.items, 'due_date').due_date)}</td>
                    <td className="w-120">{FormatLib.price(p.total)}</td>
                    {showCustomer && <td className="w-200">{p.user.name}</td>}
                    <td className="w-200">{downloadScheduleButton(p.id)}</td>
                  </tr>
                  <tr style={{ display: statusDisplay(p.id) }}>
                    <td className="w-35" />
                    <td colSpan={showCustomer ? 5 : 4}>
                      <div>
                        <table className="schedule-items-table">
                          <thead>
                            <tr>
                              <th className="w-120">{t('app.shared.payment_schedules_table.deadline')}</th>
                              <th className="w-120">{t('app.shared.payment_schedules_table.amount')}</th>
                              <th className="w-200">{t('app.shared.payment_schedules_table.state')}</th>
                              <th className="w-200" />
                            </tr>
                          </thead>
                          <tbody>
                            {_.orderBy(p.items, 'due_date').map(item => <tr key={item.id}>
                              <td>{FormatLib.date(item.due_date)}</td>
                              <td>{FormatLib.price(item.amount)}</td>
                              <td>{formatState(item, p)}</td>
                              <td>
                                <PaymentScheduleItemActions paymentScheduleItem={item}
                                  paymentSchedule={p}
                                  onError={onError}
                                  onSuccess={refreshSchedulesTable}
                                  onCardUpdateSuccess={onCardUpdateSuccess}
                                  operator={operator}
                                  displayOnceMap={displayOnceMap}
                                  show={isExpanded(p.id)}/>
                              </td>
                            </tr>)}
                          </tbody>
                        </table>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </td>
          </tr>)}
        </tbody>
      </table>
    );
  };

  /**
   * Determine which gateway is enabled and return the appropriate payment schedules
   */
  if (gateway === null) return <div/>;

  switch (gateway.value) {
    case 'stripe':
      return (
        <StripeElements>
          {renderPaymentSchedulesTable()}
        </StripeElements>
      );
    case 'payzen':
    case null:
      return (
        <div>
          {renderPaymentSchedulesTable()}
        </div>
      );
    default:
      console.error(`[PaymentSchedulesTable] Unimplemented gateway: ${gateway.value}`);
      return <div />;
  }
};
PaymentSchedulesTable.defaultProps = { showCustomer: false };

const PaymentSchedulesTableWrapper: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList, operator, onError, onCardUpdateSuccess }) => {
  return (
    <Loader>
      <PaymentSchedulesTable paymentSchedules={paymentSchedules} showCustomer={showCustomer} refreshList={refreshList} operator={operator} onError={onError} onCardUpdateSuccess={onCardUpdateSuccess} />
    </Loader>
  );
};

export { PaymentSchedulesTableWrapper as PaymentSchedulesTable };
