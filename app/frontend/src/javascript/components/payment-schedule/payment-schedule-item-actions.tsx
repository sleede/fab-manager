import {
  PaymentMethod,
  PaymentSchedule,
  PaymentScheduleItem
} from '../../models/payment-schedule';
import { ReactElement, useState } from 'react';
import * as React from 'react';
import { FabButton } from '../base/fab-button';
import { useTranslation } from 'react-i18next';
import { User } from '../../models/user';
import PaymentScheduleAPI from '../../api/payment-schedule';
import { FabModal } from '../base/fab-modal';
import FormatLib from '../../lib/format';
import { StripeConfirmModal } from '../payment/stripe/stripe-confirm-modal';
import { UpdateCardModal } from '../payment/update-card-modal';
import { UpdatePaymentMeanModal } from './update-payment-mean-modal';

// we want to display some buttons only once. This is the types of buttons it applies to.
export type TypeOnce = 'card-update'|'subscription-cancel'|'update-payment-mean';

interface PaymentScheduleItemActionsProps {
  paymentScheduleItem: PaymentScheduleItem,
  paymentSchedule: PaymentSchedule,
  onError: (message: string) => void,
  onSuccess: () => void,
  onCardUpdateSuccess: () => void
  operator: User,
  displayOnceMap: Map<TypeOnce, Map<number, number>>,
  show: boolean,
}

/**
 * This component is responsible for rendering the actions buttons for a payment schedule item.
 */
export const PaymentScheduleItemActions: React.FC<PaymentScheduleItemActionsProps> = ({ paymentScheduleItem, paymentSchedule, onError, onSuccess, onCardUpdateSuccess, displayOnceMap, operator, show }) => {
  const { t } = useTranslation('shared');

  // is open, the modal dialog to cancel the associated subscription?
  const [showCancelSubscription, setShowCancelSubscription] = useState<boolean>(false);
  // is open, the modal dialog to confirm the cashing of a check?
  const [showConfirmCashing, setShowConfirmCashing] = useState<boolean>(false);
  // is open, the modal dialog to confirm a back transfer?
  const [showConfirmTransfer, setShowConfirmTransfer] = useState<boolean>(false);
  // is open, the modal dialog the resolve a pending card payment?
  const [showResolveAction, setShowResolveAction] = useState<boolean>(false);
  // is open, the modal dialog to update the card details
  const [showUpdateCard, setShowUpdateCard] = useState<boolean>(false);
  // is open, the modal dialog to update the payment mean
  const [showUpdatePaymentMean, setShowUpdatePaymentMean] = useState<boolean>(false);
  // the user cannot confirm the action modal (3D secure), unless he has resolved the pending action
  const [isConfirmActionDisabled, setConfirmActionDisabled] = useState<boolean>(true);

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (operator.role === 'admin' || operator.role === 'manager');
  };

  /**
   * Return a button to download a PDF invoice file
   */
  const downloadInvoiceButton = (id: number): JSX.Element => {
    const link = `api/invoices/${id}/download`;
    return (
      <a href={link} target="_blank" className="download-button" rel="noreferrer">
        <i className="fas fa-download" />
        {t('app.shared.payment_schedule_item_actions.download')}
      </a>
    );
  };

  /**
   * Return a button to cancel the given subscription, if the user is privileged enough
   */
  const cancelSubscriptionButton = (): ReactElement => {
    const displayOnceStatus = displayOnceMap.get('subscription-cancel').get(paymentSchedule.id);
    if (isPrivileged() && (!displayOnceStatus || displayOnceStatus === paymentScheduleItem.id)) {
      displayOnceMap.get('subscription-cancel').set(paymentSchedule.id, paymentScheduleItem.id);
      return (
        <FabButton key={`cancel-subscription-${paymentSchedule.id}`}
          onClick={toggleCancelSubscriptionModal}
          icon={<i className="fas fa-times" />}>
          {t('app.shared.payment_schedule_item_actions.cancel_subscription')}
        </FabButton>
      );
    }
  };

  /**
   * Return a button to confirm the receipt of the bank transfer, if the user is privileged enough
   */
  const confirmTransferButton = (): ReactElement => {
    if (isPrivileged()) {
      return (
        <FabButton key={`confirm-transfer-${paymentScheduleItem.id}`}
          onClick={toggleConfirmTransferModal}
          icon={<i className="fas fa-university"/>}>
          {t('app.shared.payment_schedule_item_actions.confirm_payment')}
        </FabButton>
      );
    }
  };

  /**
   * Return a button to confirm the cashing of the check, if the user is privileged enough
   */
  const confirmCheckButton = (): ReactElement => {
    if (isPrivileged()) {
      return (
        <FabButton key={`confirm-check-${paymentScheduleItem.id}`}
          onClick={toggleConfirmCashingModal}
          icon={<i className="fas fa-check"/>}>
          {t('app.shared.payment_schedule_item_actions.confirm_check')}
        </FabButton>
      );
    }
  };

  /**
   * Return a button to resolve the 3DS security check
   */
  const solveActionButton = (): ReactElement => {
    return (
      <FabButton key={`solve-action-${paymentScheduleItem.id}`}
        onClick={toggleResolveActionModal}
        icon={<i className="fas fa-wrench"/>}>
        {t('app.shared.payment_schedule_item_actions.resolve_action')}
      </FabButton>
    );
  };

  /**
   * Return a button to update the default payment mean for the current payment schedule
   */
  const updatePaymentMeanButton = (): ReactElement => {
    const displayOnceStatus = displayOnceMap.get('update-payment-mean').get(paymentSchedule.id);
    if (isPrivileged() && (!displayOnceStatus || displayOnceStatus === paymentScheduleItem.id)) {
      displayOnceMap.get('update-payment-mean').set(paymentSchedule.id, paymentScheduleItem.id);
      return (
        <FabButton key={`update-payment-mean-${paymentScheduleItem.id}`}
          onClick={toggleUpdatePaymentMeanModal}
          icon={<i className="fas fa-money-bill-alt" />}>
          {t('app.shared.payment_schedule_item_actions.update_payment_mean')}
        </FabButton>
      );
    }
  };

  /**
   * Return a button to update the credit card associated with the payment schedule
   */
  const updateCardButton = (): ReactElement => {
    const displayOnceStatus = displayOnceMap.get('card-update').get(paymentSchedule.id);
    if (!displayOnceStatus || displayOnceStatus === paymentScheduleItem.id) {
      displayOnceMap.get('card-update').set(paymentSchedule.id, paymentScheduleItem.id);
      return (
        <FabButton key={`update-card-${paymentSchedule.id}`}
          onClick={toggleUpdateCardModal}
          icon={<i className="fas fa-credit-card"/>}>
          {t('app.shared.payment_schedule_item_actions.update_card')}
        </FabButton>
      );
    }
  };

  /**
   * Return the actions button(s) for current paymentScheduleItem with state Pending
   */
  const pendingActions = (): ReactElement => {
    if (isPrivileged()) {
      if (paymentSchedule.payment_method === PaymentMethod.Transfer) {
        return confirmTransferButton();
      }
      if (paymentSchedule.payment_method === PaymentMethod.Check) {
        return confirmCheckButton();
      }
    } else {
      return <span>{t('app.shared.payment_schedule_item_actions.please_ask_reception')}</span>;
    }
  };

  /**
   * Return the actions button(s) for current paymentScheduleItem with state Error or GatewayCanceled
   */
  const errorActions = (): ReactElement[] => {
    // if the payment schedule is canceled/in error, the schedule is over, and we can't update the card
    displayOnceMap.get('card-update').set(paymentSchedule.id, paymentScheduleItem.id);

    const buttons = [];
    if (isPrivileged()) {
      buttons.push(cancelSubscriptionButton());
      buttons.push(updatePaymentMeanButton());
    } else {
      buttons.push(<span>{t('app.shared.payment_schedule_item_actions.please_ask_reception')}</span>);
    }
    return buttons;
  };

  /**
   * Return the actions button(s) for current paymentScheduleItem with state New
   */
  const newActions = (): Array<ReactElement> => {
    const buttons = [];
    if (paymentSchedule.payment_method === PaymentMethod.Card) {
      buttons.push(updateCardButton());
    }
    if (isPrivileged()) {
      buttons.push(cancelSubscriptionButton());
    }
    return buttons;
  };

  /**
   * Show/hide the modal dialog to cancel the current subscription
   */
  const toggleCancelSubscriptionModal = (): void => {
    setShowCancelSubscription(!showCancelSubscription);
  };

  /**
   * Show/hide the modal dialog that enable to confirm the cashing of the check for a given deadline.
   */
  const toggleConfirmCashingModal = (): void => {
    setShowConfirmCashing(!showConfirmCashing);
  };

  /**
   * Show/hide the modal dialog that enable to confirm the bank transfer for a given deadline.
   */
  const toggleConfirmTransferModal = (): void => {
    setShowConfirmTransfer(!showConfirmTransfer);
  };

  /**
   * Show/hide the modal dialog that trigger the card "action".
   */
  const toggleResolveActionModal = (): void => {
    setShowResolveAction(!showResolveAction);
  };

  /**
   * Enable/disable the confirm button of the "action" modal
   */
  const toggleConfirmActionButton = (): void => {
    setConfirmActionDisabled(!isConfirmActionDisabled);
  };

  /**
   * Show/hide the modal dialog to update the bank card details
   */
  const toggleUpdateCardModal = (): void => {
    setShowUpdateCard(!showUpdateCard);
  };

  /**
   * Show/hide the modal dialog to update the payment mean
   */
  const toggleUpdatePaymentMeanModal = (): void => {
    setShowUpdatePaymentMean(!showUpdatePaymentMean);
  };

  /**
   * After the user has confirmed that he wants to cash the check, update the API, refresh the list and close the modal.
   */
  const onCheckCashingConfirmed = (): void => {
    PaymentScheduleAPI.cashCheck(paymentScheduleItem.id).then((res) => {
      if (res.state === 'paid') {
        onSuccess();
        toggleConfirmCashingModal();
      }
    });
  };

  /**
   * After the user has confirmed that he validates the transfer, update the API, refresh the list and close the modal.
   */
  const onTransferConfirmed = (): void => {
    PaymentScheduleAPI.confirmTransfer(paymentScheduleItem.id).then((res) => {
      if (res.state === 'paid') {
        onSuccess();
        toggleConfirmTransferModal();
      }
    });
  };

  /**
   * When the card was successfully updated, pay the invoice (using the new payment method) and close the modal
   */
  const handleCardUpdateSuccess = (): void => {
    if (paymentScheduleItem.state === 'requires_payment_method') {
      PaymentScheduleAPI.payItem(paymentScheduleItem.id).then(() => {
        onSuccess();
        onCardUpdateSuccess();
        toggleUpdateCardModal();
      }).catch((err) => {
        onError(err);
      });
    } else {
      // the user is updating his card number in a pro-active way, we don't need to trigger the payment
      onCardUpdateSuccess();
      toggleUpdateCardModal();
    }
  };

  /**
   * When the user has confirmed the cancellation, we transfer the request to the API
   */
  const onCancelSubscriptionConfirmed = (): void => {
    PaymentScheduleAPI.cancel(paymentSchedule.id).then(() => {
      onSuccess();
      toggleCancelSubscriptionModal();
    });
  };

  /**
   * After the 3DS confirmation was done (successfully or not), ask the API to refresh the item status,
   * then refresh the list and close the modal
   */
  const afterConfirmAction = (): void => {
    toggleConfirmActionButton();
    PaymentScheduleAPI.refreshItem(paymentScheduleItem.id).then(() => {
      onSuccess();
      toggleResolveActionModal();
    });
  };

  /**
   * When the update of the payment mean was successful, refresh the list and close the modal
   */
  const onPaymentMeanUpdateSuccess = (): void => {
    onSuccess();
    toggleUpdatePaymentMeanModal();
  };

  if (!show) return null;

  return (
    <span className="payment-schedule-item-actions">
      {paymentScheduleItem.state === 'paid' && downloadInvoiceButton(paymentScheduleItem.invoice_id)}
      {paymentScheduleItem.state === 'pending' && pendingActions()}
      {paymentScheduleItem.state === 'requires_action' && solveActionButton()}
      {paymentScheduleItem.state === 'requires_payment_method' && updateCardButton()}
      {paymentScheduleItem.state === 'error' && errorActions()}
      {paymentScheduleItem.state === 'gateway_canceled' && errorActions()}
      {paymentScheduleItem.state === 'new' && newActions()}
      <div className="modals">
        {/* Confirm the cashing of the current deadline by check */}
        <FabModal title={t('app.shared.payment_schedule_item_actions.confirm_check_cashing')}
          isOpen={showConfirmCashing}
          toggleModal={toggleConfirmCashingModal}
          onConfirm={onCheckCashingConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.payment_schedule_item_actions.confirm_button')}>
          <span>
            {t('app.shared.payment_schedule_item_actions.confirm_check_cashing_body', {
              AMOUNT: FormatLib.price(paymentScheduleItem.amount),
              DATE: FormatLib.date(paymentScheduleItem.due_date)
            })}
          </span>
        </FabModal>
        {/* Confirm the bank transfer for the current deadline */}
        <FabModal title={t('app.shared.payment_schedule_item_actions.confirm_bank_transfer')}
          isOpen={showConfirmTransfer}
          toggleModal={toggleConfirmTransferModal}
          onConfirm={onTransferConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.payment_schedule_item_actions.confirm_button')}>
          <span>
            {t('app.shared.payment_schedule_item_actions.confirm_bank_transfer_body', {
              AMOUNT: FormatLib.price(paymentScheduleItem.amount),
              DATE: FormatLib.date(paymentScheduleItem.due_date)
            })}
          </span>
        </FabModal>
        {/* Cancel the subscription */}
        <FabModal title={t('app.shared.payment_schedule_item_actions.cancel_subscription')}
          isOpen={showCancelSubscription}
          toggleModal={toggleCancelSubscriptionModal}
          onConfirm={onCancelSubscriptionConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.payment_schedule_item_actions.confirm_button')}>
          {t('app.shared.payment_schedule_item_actions.confirm_cancel_subscription')}
        </FabModal>
        {/* 3D secure confirmation */}
        <StripeConfirmModal isOpen={showResolveAction}
          toggleModal={toggleResolveActionModal}
          onSuccess={afterConfirmAction}
          paymentScheduleItemId={paymentScheduleItem.id} />
        {/* Update credit card */}
        <UpdateCardModal isOpen={showUpdateCard}
          toggleModal={toggleUpdateCardModal}
          operator={operator}
          afterSuccess={handleCardUpdateSuccess}
          onError={onError}
          schedule={paymentSchedule}>
        </UpdateCardModal>
        {/* Update the payment mean */}
        <UpdatePaymentMeanModal isOpen={showUpdatePaymentMean}
          toggleModal={toggleUpdatePaymentMeanModal}
          onError={onError}
          afterSuccess={onPaymentMeanUpdateSuccess}
          paymentSchedule={paymentSchedule} />
      </div>
    </span>
  );
};

PaymentScheduleItemActions.defaultProps = { show: false };
