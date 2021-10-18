import React, { useEffect, useState } from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import { Subscription } from '../../models/subscription';
import { User } from '../../models/user';
import { PaymentMethod } from '../../models/payment';
import { FabModal } from '../base/fab-modal';
import LocalPaymentAPI from '../../api/local-payment';
import SubscriptionAPI from '../../api/subscription';
import { Plan } from '../../models/plan';
import PlanAPI from '../../api/plan';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';

declare const Application: IApplication;

interface SubscribeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  customer: User,
  onSuccess: (message: string, subscription: Subscription) => void,
  onError: (message: string) => void,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

/**
 * Modal dialog shown to create a subscription for teh given customer
 */
const SubscribeModal: React.FC<SubscribeModalProps> = ({ isOpen, toggleModal, customer, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [plan, setPlan] = useState<number>(null);
  const [plans, setPlans] = useState<Array<Plan>>(null);

  // fetch all plans from the API on component mount
  useEffect(() => {
    PlanAPI.index()
      .then(allPlans => setPlans(allPlans))
      .catch(error => onError(error));
  }, []);

  /**
   * Callback triggered when the user validates the subscription
   */
  const handleConfirmSubscribe = (): void => {
    LocalPaymentAPI.confirmPayment({
      customer_id: customer.id,
      payment_method: PaymentMethod.Other,
      items: [
        {
          subscription: {
            plan_id: plan
          }
        }
      ]
    }).then(res => {
      SubscriptionAPI.get(res.main_object.id).then(subscription => {
        onSuccess(t('app.admin.subscribe_modal.subscription_success'), subscription);
        toggleModal();
      }).catch(error => onError(error));
    }).catch(err => onError(err));
  };

  /**
   * Callback triggered when the user selects a group in the dropdown list
   */
  const handlePlanSelect = (option: selectOption): void => {
    setPlan(option.value);
  };

  /**
   * Convert all groups to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return plans.filter(p => !p.disabled).map(p => {
      return { value: p.id, label: p.base_name };
    });
  };

  return (
    <FabModal isOpen={isOpen}
      toggleModal={toggleModal}
      className="subscribe-modal"
      title={t('app.admin.subscribe_modal.subscribe_USER', { USER: customer.name })}
      confirmButton={t('app.admin.subscribe_modal.subscribe')}
      onConfirm={handleConfirmSubscribe}
      closeButton>
      <label htmlFor="select-plan">{t('app.admin.subscribe_modal.select_plan')}</label>
      <Select id="select-plan"
        onChange={handlePlanSelect}
        options={buildOptions()} />
    </FabModal>
  );
};

const SubscribeModalWrapper: React.FC<SubscribeModalProps> = ({ isOpen, toggleModal, customer, onError, onSuccess }) => {
  return (
    <Loader>
      <SubscribeModal isOpen={isOpen} toggleModal={toggleModal} customer={customer} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('subscribeModal', react2angular(SubscribeModalWrapper, ['toggleModal', 'isOpen', 'customer', 'onError', 'onSuccess']));
