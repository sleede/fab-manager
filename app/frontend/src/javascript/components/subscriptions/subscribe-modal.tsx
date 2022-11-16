import { useEffect, useState } from 'react';
import * as React from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import { Subscription } from '../../models/subscription';
import { User } from '../../models/user';
import { PaymentMethod, ShoppingCart } from '../../models/payment';
import { FabModal } from '../base/fab-modal';
import SubscriptionAPI from '../../api/subscription';
import { Plan } from '../../models/plan';
import PlanAPI from '../../api/plan';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import FormatLib from '../../lib/format';
import { SelectSchedule } from '../payment-schedule/select-schedule';
import { ComputePriceResult } from '../../models/price';
import { PaymentScheduleSummary } from '../payment-schedule/payment-schedule-summary';
import { PaymentSchedule } from '../../models/payment-schedule';
import PriceAPI from '../../api/price';
import { LocalPaymentModal } from '../payment/local-payment/local-payment-modal';
import { SelectOption } from '../../models/select';

declare const Application: IApplication;

interface SubscribeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  customer: User,
  operator: User,
  onSuccess: (message: string, subscription: Subscription) => void,
  onError: (message: string) => void,
}

/**
 * Modal dialog shown to create a subscription for the given customer
 */
export const SubscribeModal: React.FC<SubscribeModalProps> = ({ isOpen, toggleModal, customer, operator, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [selectedPlan, setSelectedPlan] = useState<Plan>(null);
  const [selectedSchedule, setSelectedSchedule] = useState<boolean>(false);
  const [allPlans, setAllPlans] = useState<Array<Plan>>(null);
  const [price, setPrice] = useState<ComputePriceResult>(null);
  const [cart, setCart] = useState<ShoppingCart>(null);
  const [localPaymentModal, setLocalPaymentModal] = useState<boolean>(false);

  // fetch all plans from the API on component mount
  useEffect(() => {
    PlanAPI.index()
      .then(plans => setAllPlans(plans))
      .catch(error => onError(error));
  }, []);

  // when the plan is updated, update the default value for the payment schedule requirement
  useEffect(() => {
    if (!selectedPlan) return;

    setSelectedSchedule(selectedPlan.monthly_payment);
  }, [selectedPlan]);

  // when the plan or the requirement for a payment schedule are updated, update the cart accordingly
  useEffect(() => {
    if (!selectedPlan) return;

    setCart({
      customer_id: customer.id,
      items: [{
        subscription: {
          plan_id: selectedPlan.id
        }
      }],
      payment_method: PaymentMethod.Other,
      payment_schedule: selectedSchedule
    });
  }, [selectedSchedule, selectedPlan]);

  // when the cart is updated, update the price accordingly
  useEffect(() => {
    if (!cart) return;

    PriceAPI.compute(cart)
      .then(res => setPrice(res))
      .catch(err => onError(err));
  }, [cart]);

  /**
   * Callback triggered when the user selects a group in the dropdown list
   */
  const handlePlanSelect = (option: SelectOption<number>): void => {
    const plan = allPlans.find(p => p.id === option.value);
    setSelectedPlan(plan);
  };

  /**
   * Callback triggered when the payment of the subscription was successful
   */
  const onPaymentSuccess = (res): void => {
    SubscriptionAPI.get(res.main_object.id).then(subscription => {
      onSuccess(t('app.admin.subscribe_modal.subscription_success'), subscription);
      toggleModal();
    }).catch(error => onError(error));
  };

  /**
   * Open/closes the local payment modal
   */
  const toggleLocalPaymentModal = (): void => {
    setLocalPaymentModal(!localPaymentModal);
  };

  /**
   * Convert all groups to the react-select format
   */
  const buildOptions = (): Array<SelectOption<number>> => {
    if (!allPlans) return [];

    return allPlans.filter(p => !p.disabled && p.group_id === customer.group_id).map(p => {
      return { value: p.id, label: `${p.base_name} (${FormatLib.duration(p.interval, p.interval_count)})` };
    });
  };

  return (
    <FabModal isOpen={isOpen}
      toggleModal={toggleModal}
      className="subscribe-modal"
      title={t('app.admin.subscribe_modal.subscribe_USER', { USER: customer.name })}
      confirmButton={t('app.admin.subscribe_modal.subscribe')}
      onConfirm={toggleLocalPaymentModal}
      closeButton>
      <div className="options">
        <label htmlFor="select-plan">{t('app.admin.subscribe_modal.select_plan')}</label>
        <Select id="select-plan"
          onChange={handlePlanSelect}
          options={buildOptions()} />

        <SelectSchedule show={selectedPlan?.monthly_payment} selected={selectedSchedule} onChange={setSelectedSchedule} />
      </div>
      <div className="summary">
        {price?.schedule && <PaymentScheduleSummary schedule={price.schedule as PaymentSchedule} />}
        {price && !price.schedule && <div className="one-go-payment">
          <h4>{t('app.admin.subscribe_modal.pay_in_one_go')}</h4>
          <span>{FormatLib.price(price.price)}</span>
        </div>}
      </div>
      <LocalPaymentModal isOpen={localPaymentModal}
        toggleModal={toggleLocalPaymentModal}
        afterSuccess={onPaymentSuccess}
        onError={onError}
        cart={cart}
        updateCart={setCart}
        currentUser={operator}
        customer={customer}
        schedule={price?.schedule as PaymentSchedule} />
    </FabModal>
  );
};

const SubscribeModalWrapper: React.FC<SubscribeModalProps> = ({ isOpen, toggleModal, customer, operator, onError, onSuccess }) => {
  return (
    <Loader>
      <SubscribeModal isOpen={isOpen} toggleModal={toggleModal} customer={customer} operator={operator} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('subscribeModal', react2angular(SubscribeModalWrapper, ['toggleModal', 'isOpen', 'customer', 'operator', 'onError', 'onSuccess']));
