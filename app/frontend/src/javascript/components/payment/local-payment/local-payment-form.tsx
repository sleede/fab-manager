import * as React from 'react';
import { FormEvent, useEffect, useState } from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import { GatewayFormProps } from '../abstract-payment-modal';
import LocalPaymentAPI from '../../../api/local-payment';
import FormatLib from '../../../lib/format';
import SettingAPI from '../../../api/setting';
import { CardPaymentModal } from '../card-payment-modal';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { HtmlTranslate } from '../../base/html-translate';
import CheckoutAPI from '../../../api/checkout';
import { SelectOption } from '../../../models/select';
import { PaymentMethod } from '../../../models/payment';

const ALL_SCHEDULE_METHODS = ['card', 'check', 'transfer'] as const;
type scheduleMethod = typeof ALL_SCHEDULE_METHODS[number];

/**
 * A form component to ask for confirmation before cashing a payment directly at the FabLab's reception.
 * This is intended for use by privileged users.
 * The form validation button must be created elsewhere, using the attribute form={formId}.
 */
export const LocalPaymentForm: React.FC<GatewayFormProps> = ({ onSubmit, onSuccess, onError, children, className, paymentSchedule, cart, updateCart, customer, operator, formId, order }) => {
  const { t } = useTranslation('admin');

  const [method, setMethod] = useState<scheduleMethod>('check');
  const [onlinePaymentModal, setOnlinePaymentModal] = useState<boolean>(false);

  useEffect(() => {
    setMethod(cart.payment_method || 'check');
    if (cart.payment_method === '') {
      cart.payment_method = PaymentMethod.Check;
    }
  }, [cart]);

  /**
   * Open/closes the online payment modal, used to collect card credentials when paying the payment schedule by card.
   */
  const toggleOnlinePaymentModal = (): void => {
    setOnlinePaymentModal(!onlinePaymentModal);
  };

  /**
   * Convert all payement methods for schedules to the react-select format
   */
  const buildMethodOptions = (): Array<SelectOption<scheduleMethod>> => {
    return ALL_SCHEDULE_METHODS.map(i => methodToOption(i));
  };

  /**
   * Convert the given payment-method to the react-select format
   */
  const methodToOption = (value: scheduleMethod): SelectOption<scheduleMethod> => {
    if (!value) return { value, label: '' };

    return { value, label: t(`app.admin.local_payment_form.method_${value}`) };
  };

  /**
   * Callback triggered when the user selects a payment method for the current payment schedule.
   */
  const handleUpdateMethod = (option: SelectOption<scheduleMethod>) => {
    updateCart(Object.assign({}, cart, { payment_method: option.value }));
    setMethod(option.value);
  };

  /**
   * Handle the submission of the form. It will process the local payment.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    onSubmit();

    if (paymentSchedule && method === 'card') {
      // check that the online payment is active
      try {
        const online = await SettingAPI.get('online_payment_module');
        if (online.value !== 'true') {
          return onError(t('app.admin.local_payment_form.online_payment_disabled'));
        }
        return toggleOnlinePaymentModal();
      } catch (e) {
        onError(e);
      }
    }

    try {
      let res;
      if (order) {
        res = await CheckoutAPI.payment(order);
        res = res.order;
      } else {
        res = await LocalPaymentAPI.confirmPayment(cart);
      }
      onSuccess(res);
    } catch (e) {
      onError(e);
    }
  };

  /**
   * Callback triggered after a successful payment by online card for a schedule.
   */
  const afterCreatePaymentSchedule = (document: PaymentSchedule) => {
    toggleOnlinePaymentModal();
    onSuccess(document);
  };

  /**
   * Generally, this form component is only shown to admins or to managers when they book for someone else.
   * If this is not the case, then it is shown to validate a free (or prepaid by wallet) cart.
   * This function will return `true` in the later case.
   */
  const isFreeOfCharge = (): boolean => {
    return (customer.id === operator.id);
  };

  /**
   * Get the type of the main item in the cart compile
   */
  const mainItemType = (): string => {
    if (order) {
      return '';
    }
    return Object.keys(cart.items[0])[0];
  };

  return (
    <form onSubmit={handleSubmit} id={formId} className={`local-payment-form ${className || ''}`}>
      {!paymentSchedule && !isFreeOfCharge() && <p className="payment">{t('app.admin.local_payment_form.about_to_cash')}</p>}
      {!paymentSchedule && isFreeOfCharge() && <p className="payment">{t('app.admin.local_payment_form.about_to_confirm', { ITEM: mainItemType() })}</p>}
      {paymentSchedule && <div className="payment-schedule">
        <div className="schedule-method">
          <label htmlFor="payment-method">{t('app.admin.local_payment_form.payment_method')}</label>
          <Select placeholder={ t('app.admin.local_payment_form.payment_method') }
            id="payment-method"
            className="method-select"
            onChange={handleUpdateMethod}
            options={buildMethodOptions()}
            value={methodToOption(method)} />
          {method === 'card' && <p>{t('app.admin.local_payment_form.card_collection_info')}</p>}
          {method === 'check' && <p>{t('app.admin.local_payment_form.check_collection_info', { DEADLINES: paymentSchedule.items.length })}</p>}
          {method === 'transfer' && <HtmlTranslate trKey="app.admin.local_payment_form.transfer_collection_info" options={{ DEADLINES: paymentSchedule.items.length }} />}
        </div>
        <div className="full-schedule">
          <ul>
            {paymentSchedule.items.map(item => {
              return (
                <li key={`${item.due_date}`}>
                  <span className="schedule-item-date">{FormatLib.date(item.due_date)}</span>
                  <span> </span>
                  <span className="schedule-item-price">{FormatLib.price(item.amount)}</span>
                </li>
              );
            })}
          </ul>
        </div>
        <CardPaymentModal isOpen={onlinePaymentModal}
          toggleModal={toggleOnlinePaymentModal}
          afterSuccess={afterCreatePaymentSchedule}
          onError={onError}
          cart={cart}
          currentUser={operator}
          customer={customer}
          schedule={paymentSchedule} />
      </div>}
      {children}
    </form>
  );
};
