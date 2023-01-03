import { IApplication } from '../../models/application';
import { Subscription } from '../../models/subscription';
import { FabModal } from '../base/fab-modal';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import * as React from 'react';
import SubscriptionAPI from '../../api/subscription';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';

declare const Application: IApplication;

interface CancelSubscriptionModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  subscription: Subscription,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * Modam dialog shown to confirm the cancelation of the current running subscription of a customer
 */
export const CancelSubscriptionModal: React.FC<CancelSubscriptionModalProps> = ({ isOpen, toggleModal, subscription, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  /**
   * Callback triggered when the user has confirmed the cancelation of the subscription
   */
  const handleCancelConfirmed = () => {
    SubscriptionAPI.cancel(subscription.id).then(() => {
      toggleModal();
      onSuccess(t('app.admin.cancel_subscription_modal.subscription_canceled'));
    }).catch(onError);
  };

  return (
    <FabModal isOpen={isOpen}
              toggleModal={toggleModal}
              confirmButton={t('app.admin.cancel_subscription_modal.confirm')}
              title={t('app.admin.cancel_subscription_modal.title')}
              onConfirm={handleCancelConfirmed}
              closeButton>
      <HtmlTranslate trKey={'app.admin.cancel_subscription_modal.confirmation_html'} options={{ NAME: subscription.plan.base_name }} />
    </FabModal>
  );
};

const CancelSubscriptionModalWrapper: React.FC<CancelSubscriptionModalProps> = (props) => {
  return (
    <Loader>
      <CancelSubscriptionModal {...props} />
    </Loader>
  );
};

Application.Components.component('cancelSubscriptionModal', react2angular(CancelSubscriptionModalWrapper, ['toggleModal', 'subscription', 'isOpen', 'onError', 'onSuccess']));
