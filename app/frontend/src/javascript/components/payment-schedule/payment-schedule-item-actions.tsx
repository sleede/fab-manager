import { PaymentSchedule, PaymentScheduleItem } from '../../models/payment-schedule';
import React, { ReactElement, ReactEventHandler, useEffect, useState } from 'react';
import { FabButton } from '../base/fab-button';
import { useTranslation } from 'react-i18next';
import { User, UserRole } from '../../models/user';

// we want to display some buttons only once. This is the types of buttons it applies to.
enum TypeOnce {
  CardUpdate = 'card-update',
  SubscriptionCancel = 'subscription-cancel',
}

interface PaymentScheduleItemActionsProps {
  paymentScheduleItem: PaymentScheduleItem,
  onError: (message: string) => void,
  operator: User,
  displayOnceMap: Map<TypeOnce, Map<number, boolean>>,
}

/**
 * This component is responsible for rendering the actions buttons for a payment schedule item.
 */
export const PaymentScheduleItemActions: React.FC<PaymentScheduleItemActionsProps> = ({ paymentScheduleItem, onError, displayOnceMap, operator }) => {
  const { t } = useTranslation('shared');

  // is open, the modal dialog to cancel the associated subscription?
  const [showCancelSubscription, setShowCancelSubscription] = useState<boolean>(false);
  // is open, the modal dialog to confirm the cashing of a check?
  const [showConfirmCashing, setShowConfirmCashing] = useState<boolean>(false);
  // is open, the modal dialog to confirm a back transfer?
  const [showConfirmTransfer, setShowConfirmTransfer] = useState<boolean>(false);
  // is open, the modal dialog the resolve a pending card payment?
  const [showResolveAction, setShowResolveAction] = useState<boolean>(false);

  useEffect(() => {
    Object.keys(TypeOnce).forEach((type) => {
      displayOnceMap.set(TypeOnce[type], new Map<number, boolean>());
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
  const cancelSubscriptionButton = (schedule: PaymentSchedule): ReactElement => {
    if (isPrivileged() && !displayOnceMap.get(TypeOnce.SubscriptionCancel).get(schedule.id)) {
      displayOnceMap.get(TypeOnce.SubscriptionCancel).set(schedule.id, true);
      return (
        <FabButton onClick={toggleCancelSubscriptionModal}
          icon={<i className="fas fa-times" />}>
          {t('app.shared.payment_schedule_item_actions.cancel_subscription')}
        </FabButton>
      );
    }
  };

  const confirmTransferButton = (): ReactElement => {
    return (
      <FabButton onClick={toggleConfirmTransferModal}
        icon={<i className="fas fa-university"/>}>
        {t('app.shared.payment_schedule_item_actions.confirm_payment')}
      </FabButton>
    );
  };

  const confirmCheckButton = (): ReactElement => {
    return (
      <FabButton onClick={toggleConfirmCashingModal}
        icon={<i className="fas fa-check"/>}>
        {t('app.shared.payment_schedule_item_actions.confirm_check')}
      </FabButton>
    );
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

  return (
    <div className="payment-schedule-item-actions">

    </div>
  );
};
