import {
  PaymentMethod,
  PaymentSchedule,
  PaymentScheduleItem,
  PaymentScheduleItemState
} from '../../models/payment-schedule';
import React, { ReactElement, useEffect, useState } from 'react';
import { FabButton } from '../base/fab-button';
import { useTranslation } from 'react-i18next';
import { User, UserRole } from '../../models/user';
import PaymentScheduleAPI from '../../api/payment-schedule';
import { FabModal } from '../base/fab-modal';
import FormatLib from '../../lib/format';
import { StripeElements } from '../payment/stripe/stripe-elements';
import { StripeConfirmModal } from '../payment/stripe/stripe-confirm-modal';
import { UpdateCardModal } from '../payment/update-card-modal';

// we want to display some buttons only once. This is the types of buttons it applies to.
export enum TypeOnce {
  CardUpdate = 'card-update',
  SubscriptionCancel = 'subscription-cancel',
}

interface PaymentScheduleItemActionsProps {
  paymentScheduleItem: PaymentScheduleItem,
  paymentSchedule: PaymentSchedule,
  onError: (message: string) => void,
  onSuccess: () => void,
  onCardUpdateSuccess: () => void
  operator: User,
  displayOnceMap: Map<TypeOnce, Map<number, boolean>>,
}

/**
 * This component is responsible for rendering the actions buttons for a payment schedule item.
 */
export const PaymentScheduleItemActions: React.FC<PaymentScheduleItemActionsProps> = ({ paymentScheduleItem, paymentSchedule, onError, onSuccess, onCardUpdateSuccess, displayOnceMap, operator }) => {
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
  // the user cannot confirm the action modal (3D secure), unless he has resolved the pending action
  const [isConfirmActionDisabled, setConfirmActionDisabled] = useState<boolean>(true);

  useEffect(() => {
    Object.keys(TypeOnce).forEach((type) => {
      if (!displayOnceMap.has(type as TypeOnce)) {
        displayOnceMap.set(type as TypeOnce, new Map<number, boolean>());
      }
    });
  }, []);

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (operator.role === UserRole.Admin || operator.role === UserRole.Manager);
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
    if (isPrivileged() && !displayOnceMap.get(TypeOnce.SubscriptionCancel).get(paymentSchedule.id)) {
      displayOnceMap.get(TypeOnce.SubscriptionCancel).set(paymentSchedule.id, true);
      return (
        <FabButton onClick={toggleCancelSubscriptionModal}
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
        <FabButton onClick={toggleConfirmTransferModal}
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
        <FabButton onClick={toggleConfirmCashingModal}
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
      <FabButton onClick={toggleResolveActionModal}
        icon={<i className="fas fa-wrench"/>}>
        {t('app.shared.payment_schedule_item_actions.resolve_action')}
      </FabButton>
    );
  };

  /**
   * Return a button to update the credit card associated with the payment schedule
   */
  const updateCardButton = (): ReactElement => {
    if (!displayOnceMap.get(TypeOnce.CardUpdate).get(paymentSchedule.id)) {
      displayOnceMap.get(TypeOnce.CardUpdate).set(paymentSchedule.id, true);
      return (
        <FabButton onClick={toggleUpdateCardModal}
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
  const errorActions = (): ReactElement => {
    // if the payment schedule is canceled/in error, the schedule is over, and we can't update the card
    displayOnceMap.get(TypeOnce.CardUpdate).set(paymentSchedule.id, true);
    if (isPrivileged()) {
      return cancelSubscriptionButton();
    } else {
      return <span>{t('app.shared.payment_schedule_item_actions.please_ask_reception')}</span>;
    }
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
   * After the user has confirmed that he wants to cash the check, update the API, refresh the list and close the modal.
   */
  const onCheckCashingConfirmed = (): void => {
    PaymentScheduleAPI.cashCheck(paymentScheduleItem.id).then((res) => {
      if (res.state === PaymentScheduleItemState.Paid) {
        onSuccess();
        toggleConfirmCashingModal();
      }
    });
  };

  /**
   * After the user has confirmed that he validates the tranfer, update the API, refresh the list and close the modal.
   */
  const onTransferConfirmed = (): void => {
    PaymentScheduleAPI.confirmTransfer(paymentSchedule.id).then((res) => {
      if (res.state === PaymentScheduleItemState.Paid) {
        onSuccess();
        toggleConfirmTransferModal();
      }
    });
  };

  /**
   * When the card was successfully updated, pay the invoice (using the new payment method) and close the modal
   */
  const handleCardUpdateSuccess = (): void => {
    if (paymentScheduleItem.state === PaymentScheduleItemState.RequirePaymentMethod) {
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

  if (!displayOnceMap.get(TypeOnce.CardUpdate) || !displayOnceMap.get(TypeOnce.SubscriptionCancel)) return null;

  return (
    <span className="payment-schedule-item-actions">
      {paymentScheduleItem.state === PaymentScheduleItemState.Paid && downloadInvoiceButton(paymentScheduleItem.invoice_id)}
      {paymentScheduleItem.state === PaymentScheduleItemState.Pending && pendingActions()}
      {paymentScheduleItem.state === PaymentScheduleItemState.RequireAction && solveActionButton()}
      {paymentScheduleItem.state === PaymentScheduleItemState.RequirePaymentMethod && updateCardButton()}
      {paymentScheduleItem.state === PaymentScheduleItemState.Error && errorActions()}
      {paymentScheduleItem.state === PaymentScheduleItemState.GatewayCanceled && errorActions()}
      {paymentScheduleItem.state === PaymentScheduleItemState.New && newActions()}
      <div className="modals">
        {/* Confirm the cashing of the current deadline by check */}
        <FabModal title={t('app.shared.schedules_table.confirm_check_cashing')}
          isOpen={showConfirmCashing}
          toggleModal={toggleConfirmCashingModal}
          onConfirm={onCheckCashingConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.schedules_table.confirm_button')}>
          <span>
            {t('app.shared.schedules_table.confirm_check_cashing_body', {
              AMOUNT: FormatLib.price(paymentScheduleItem.amount),
              DATE: FormatLib.date(paymentScheduleItem.due_date)
            })}
          </span>
        </FabModal>
        {/* Confirm the bank transfer for the current deadline */}
        <FabModal title={t('app.shared.schedules_table.confirm_bank_transfer')}
          isOpen={showConfirmTransfer}
          toggleModal={toggleConfirmTransferModal}
          onConfirm={onTransferConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.schedules_table.confirm_button')}>
          <span>
            {t('app.shared.schedules_table.confirm_bank_transfer_body', {
              AMOUNT: FormatLib.price(paymentScheduleItem.amount),
              DATE: FormatLib.date(paymentScheduleItem.due_date)
            })}
          </span>
        </FabModal>
        {/* Cancel the subscription */}
        <FabModal title={t('app.shared.schedules_table.cancel_subscription')}
          isOpen={showCancelSubscription}
          toggleModal={toggleCancelSubscriptionModal}
          onConfirm={onCancelSubscriptionConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.schedules_table.confirm_button')}>
          {t('app.shared.schedules_table.confirm_cancel_subscription')}
        </FabModal>
        <StripeElements>
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
        </StripeElements>
      </div>
    </span>
  );
};
