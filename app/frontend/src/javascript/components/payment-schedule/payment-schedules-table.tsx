import React, { ReactElement, ReactEventHandler, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';
import _ from 'lodash';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { UpdateCardModal } from '../payment/update-card-modal';
import { StripeElements } from '../payment/stripe/stripe-elements';
import { User, UserRole } from '../../models/user';
import { PaymentSchedule, PaymentScheduleItem, PaymentScheduleItemState } from '../../models/payment-schedule';
import PaymentScheduleAPI from '../../api/payment-schedule';
import FormatLib from '../../lib/format';
import { StripeConfirmModal } from '../payment/stripe/stripe-confirm-modal';

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
const PaymentSchedulesTableComponent: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList, operator, onError, onCardUpdateSuccess }) => {
  const { t } = useTranslation('shared');

  // for each payment schedule: are the details (all deadlines) shown or hidden?
  const [showExpanded, setShowExpanded] = useState<Map<number, boolean>>(new Map());
  // is open, the modal dialog to confirm the cashing of a check?
  const [showConfirmCashing, setShowConfirmCashing] = useState<boolean>(false);
  // is open, the modal dialog to confirm a back transfer?
  const [showConfirmTransfer, setShowConfirmTransfer] = useState<boolean>(false);
  // is open, the modal dialog the resolve a pending card payment?
  const [showResolveAction, setShowResolveAction] = useState<boolean>(false);
  // the user cannot confirm the action modal (3D secure), unless he has resolved the pending action
  const [isConfirmActionDisabled, setConfirmActionDisabled] = useState<boolean>(true);
  // is open, the modal dialog to update the card details
  const [showUpdateCard, setShowUpdateCard] = useState<boolean>(false);
  // when an action is triggered on a deadline, the deadline is saved here until the action is done or cancelled.
  const [tempDeadline, setTempDeadline] = useState<PaymentScheduleItem>(null);
  // when an action is triggered on a deadline, the parent schedule is saved here until the action is done or cancelled.
  const [tempSchedule, setTempSchedule] = useState<PaymentSchedule>(null);
  // is open, the modal dialog to cancel the associated subscription?
  const [showCancelSubscription, setShowCancelSubscription] = useState<boolean>(false);

  // we want to display the card update button, only once. This is an association table keeping when we already shown one
  const cardUpdateButton = new Map<number, boolean>();
  // we want to display the cancel subscription button, only once. This is an association table keeping when we already shown one
  const subscriptionCancelButton = new Map<number, boolean>();

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
      return <i className="fas fa-minus-square" />;
    } else {
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
   * For use with downloadButton()
   */
  enum TargetType {
    Invoice = 'invoices',
    PaymentSchedule = 'payment_schedules'
  }

  /**
   * Return a button to download a PDF file, may be an invoice, or a payment schedule, depending or the provided parameters
   */
  const downloadButton = (target: TargetType, id: number): JSX.Element => {
    const link = `api/${target}/${id}/download`;
    return (
      <a href={link} target="_blank" className="download-button" rel="noreferrer">
        <i className="fas fa-download" />
        {t('app.shared.schedules_table.download')}
      </a>
    );
  };

  /**
   * Return a button to cancel the given subscription, if the user is privileged enough
   */
  const cancelSubscriptionButton = (schedule: PaymentSchedule): ReactElement => {
    if (isPrivileged() && !subscriptionCancelButton.get(schedule.id)) {
      subscriptionCancelButton.set(schedule.id, true);
      return (
        <FabButton onClick={handleCancelSubscription(schedule)}
          icon={<i className="fas fa-times" />}>
          {t('app.shared.schedules_table.cancel_subscription')}
        </FabButton>
      );
    }
  };

  /**
   * Return the human-readable string for the status of the provided deadline.
   */
  const formatState = (item: PaymentScheduleItem, schedule: PaymentSchedule): JSX.Element => {
    let res = t(`app.shared.schedules_table.state_${item.state}${item.state === 'pending' ? '_' + schedule.payment_method : ''}`);
    if (item.state === PaymentScheduleItemState.Paid) {
      const key = `app.shared.schedules_table.method_${item.payment_method}`;
      res += ` (${t(key)})`;
    }
    return <span className={`state-${item.state}`}>{res}</span>;
  };

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (operator.role === UserRole.Admin || operator.role === UserRole.Manager);
  };

  /**
   * Return the action button(s) for the given deadline
   */
  const itemButtons = (item: PaymentScheduleItem, schedule: PaymentSchedule): JSX.Element => {
    switch (item.state) {
      case PaymentScheduleItemState.Paid:
        return downloadButton(TargetType.Invoice, item.invoice_id);
      case PaymentScheduleItemState.Pending:
        if (isPrivileged()) {
          if (schedule.payment_method === 'transfer') {
            return (
              <FabButton onClick={handleConfirmTransferPayment(item)}
                icon={<i className="fas fa-university"/>}>
                {t('app.shared.schedules_table.confirm_payment')}
              </FabButton>
            );
          } else {
            return (
              <FabButton onClick={handleConfirmCheckPayment(item)}
                icon={<i className="fas fa-money-check"/>}>
                {t('app.shared.schedules_table.confirm_payment')}
              </FabButton>
            );
          }
        } else {
          return <span>{t('app.shared.schedules_table.please_ask_reception')}</span>;
        }
      case PaymentScheduleItemState.RequireAction:
        return (
          <FabButton onClick={handleSolveAction(item)}
            icon={<i className="fas fa-wrench" />}>
            {t('app.shared.schedules_table.solve')}
          </FabButton>
        );
      case PaymentScheduleItemState.RequirePaymentMethod:
        return (
          <FabButton onClick={handleUpdateCard(schedule, item)}
            icon={<i className="fas fa-credit-card" />}>
            {t('app.shared.schedules_table.update_card')}
          </FabButton>
        );
      case PaymentScheduleItemState.Error:
        // if the payment is in error, the schedule is over, and we can't update the card
        cardUpdateButton.set(schedule.id, true);
        if (!isPrivileged()) {
          return <span>{t('app.shared.schedules_table.please_ask_reception')}</span>;
        }
        return cancelSubscriptionButton(schedule);
      case PaymentScheduleItemState.New:
        if (!cardUpdateButton.get(schedule.id) && schedule.payment_method === 'card') {
          cardUpdateButton.set(schedule.id, true);
          return (
            <span>
              <FabButton onClick={handleUpdateCard(schedule)}
                icon={<i className="fas fa-credit-card" />}>
                {t('app.shared.schedules_table.update_card')}
              </FabButton>
              {cancelSubscriptionButton(schedule)}
            </span>
          );
        } else {
          return cancelSubscriptionButton(schedule);
        }
        return <span />;
      default:
        return <span />;
    }
  };

  /**
   * Callback triggered when the user's clicks on the "cash check" button: show a confirmation modal
   */
  const handleConfirmCheckPayment = (item: PaymentScheduleItem): ReactEventHandler => {
    return (): void => {
      setTempDeadline(item);
      toggleConfirmCashingModal();
    };
  };

  /**
   * Callback triggered when the user's clicks on the "confirm transfer" button: show a confirmation modal
   */
  const handleConfirmTransferPayment = (item: PaymentScheduleItem): ReactEventHandler => {
    return (): void => {
      setTempDeadline(item);
      toggleConfirmTransferModal();
    };
  };
  /**
   * After the user has confirmed that he wants to cash the check, update the API, refresh the list and close the modal.
   */
  const onCheckCashingConfirmed = (): void => {
    PaymentScheduleAPI.cashCheck(tempDeadline.id).then((res) => {
      if (res.state === PaymentScheduleItemState.Paid) {
        refreshSchedulesTable();
        toggleConfirmCashingModal();
      }
    });
  };

  /**
   * After the user has confirmed that he validates the tranfer, update the API, refresh the list and close the modal.
   */
  const onTransferConfirmed = (): void => {
    PaymentScheduleAPI.confirmTransfer(tempDeadline.id).then((res) => {
      if (res.state === PaymentScheduleItemState.Paid) {
        refreshSchedulesTable();
        toggleConfirmTransferModal();
      }
    });
  };

  /**
   * Refresh all payment schedules in the table
   */
  const refreshSchedulesTable = (): void => {
    refreshList();
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
   * Callback triggered when the user's clicks on the "resolve" button: show a modal that will trigger the action
   */
  const handleSolveAction = (item: PaymentScheduleItem): ReactEventHandler => {
    return (): void => {
      setTempDeadline(item);
      toggleResolveActionModal();
    };
  };

  /**
   * After the action was done (successfully or not), ask the API to refresh the item status, then refresh the list and close the modal
   */
  const afterAction = (): void => {
    toggleConfirmActionButton();
    PaymentScheduleAPI.refreshItem(tempDeadline.id).then(() => {
      refreshSchedulesTable();
      toggleResolveActionModal();
    });
  };

  /**
   * Enable/disable the confirm button of the "action" modal
   */
  const toggleConfirmActionButton = (): void => {
    setConfirmActionDisabled(!isConfirmActionDisabled);
  };

  /**
   * Callback triggered when the user's clicks on the "update card" button: show a modal to input a new card.
   * If a payementScheduleItem is provided, the payment will be triggered after a successful update (see handleCardUpdateSuccess).
   */
  const handleUpdateCard = (paymentSchedule: PaymentSchedule, item?: PaymentScheduleItem): ReactEventHandler => {
    return (): void => {
      setTempDeadline(item);
      setTempSchedule(paymentSchedule);
      toggleUpdateCardModal();
    };
  };

  /**
   * Show/hide the modal dialog to update the bank card details
   */
  const toggleUpdateCardModal = (): void => {
    setShowUpdateCard(!showUpdateCard);
  };

  /**
   * When the card was successfully updated, pay the invoice (using the new payment method) and close the modal
   */
  const handleCardUpdateSuccess = (): void => {
    if (tempDeadline) {
      PaymentScheduleAPI.payItem(tempDeadline.id).then(() => {
        refreshSchedulesTable();
        onCardUpdateSuccess();
        toggleUpdateCardModal();
      }).catch((err) => {
        handleCardUpdateError(err);
      });
    } else {
      // if no tempDeadline (i.e. PaymentScheduleItem), then the user is updating his card number in a pro-active way, we don't need to trigger the payment
      onCardUpdateSuccess();
      toggleUpdateCardModal();
    }
  };

  /**
   * When the card was not updated, raise the error
   */
  const handleCardUpdateError = (error): void => {
    onError(error);
  };

  /**
   * Callback triggered when the user clicks on the "cancel subscription" button
   */
  const handleCancelSubscription = (schedule: PaymentSchedule): ReactEventHandler => {
    return (): void => {
      setTempSchedule(schedule);
      toggleCancelSubscriptionModal();
    };
  };

  /**
   * Show/hide the modal dialog to cancel the current subscription
   */
  const toggleCancelSubscriptionModal = (): void => {
    setShowCancelSubscription(!showCancelSubscription);
  };

  /**
   * When the user has confirmed the cancellation, we transfer the request to the API
   */
  const onCancelSubscriptionConfirmed = (): void => {
    PaymentScheduleAPI.cancel(tempSchedule.id).then(() => {
      refreshSchedulesTable();
      toggleCancelSubscriptionModal();
    });
  };

  return (
    <div>
      <table className="schedules-table">
        <thead>
          <tr>
            <th className="w-35" />
            <th className="w-200">{t('app.shared.schedules_table.schedule_num')}</th>
            <th className="w-200">{t('app.shared.schedules_table.date')}</th>
            <th className="w-120">{t('app.shared.schedules_table.price')}</th>
            {showCustomer && <th className="w-200">{t('app.shared.schedules_table.customer')}</th>}
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
                    <td className="w-200">{downloadButton(TargetType.PaymentSchedule, p.id)}</td>
                  </tr>
                  <tr style={{ display: statusDisplay(p.id) }}>
                    <td className="w-35" />
                    <td colSpan={showCustomer ? 5 : 4}>
                      <div>
                        <table className="schedule-items-table">
                          <thead>
                            <tr>
                              <th className="w-120">{t('app.shared.schedules_table.deadline')}</th>
                              <th className="w-120">{t('app.shared.schedules_table.amount')}</th>
                              <th className="w-200">{t('app.shared.schedules_table.state')}</th>
                              <th className="w-200" />
                            </tr>
                          </thead>
                          <tbody>
                            {_.orderBy(p.items, 'due_date').map(item => <tr key={item.id}>
                              <td>{FormatLib.date(item.due_date)}</td>
                              <td>{FormatLib.price(item.amount)}</td>
                              <td>{formatState(item, p)}</td>
                              <td>{itemButtons(item, p)}</td>
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
      <div className="modals">
        {/* Confirm the cashing of the current deadline by check */}
        <FabModal title={t('app.shared.schedules_table.confirm_check_cashing')}
          isOpen={showConfirmCashing}
          toggleModal={toggleConfirmCashingModal}
          onConfirm={onCheckCashingConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.schedules_table.confirm_button')}>
          {tempDeadline && <span>
            {t('app.shared.schedules_table.confirm_check_cashing_body', {
              AMOUNT: FormatLib.price(tempDeadline.amount),
              DATE: FormatLib.date(tempDeadline.due_date)
            })}
          </span>}
        </FabModal>
        {/* Confirm the bank transfer for the current deadline */}
        <FabModal title={t('app.shared.schedules_table.confirm_bank_transfer')}
          isOpen={showConfirmTransfer}
          toggleModal={toggleConfirmTransferModal}
          onConfirm={onTransferConfirmed}
          closeButton={true}
          confirmButton={t('app.shared.schedules_table.confirm_button')}>
          {tempDeadline && <span>
            {t('app.shared.schedules_table.confirm_bank_transfer_body', {
              AMOUNT: FormatLib.price(tempDeadline.amount),
              DATE: FormatLib.date(tempDeadline.due_date)
            })}
          </span>}
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
          {tempDeadline && <StripeConfirmModal isOpen={showResolveAction}
            toggleModal={toggleResolveActionModal}
            onSuccess={afterAction}
            paymentScheduleItemId={tempDeadline.id} />}
          {/* Update credit card */}
          {tempSchedule && <UpdateCardModal isOpen={showUpdateCard}
            toggleModal={toggleUpdateCardModal}
            operator={operator}
            afterSuccess={handleCardUpdateSuccess}
            onError={handleCardUpdateError}
            schedule={tempSchedule}>
          </UpdateCardModal>}
        </StripeElements>
      </div>
    </div>
  );
};
PaymentSchedulesTableComponent.defaultProps = { showCustomer: false };

export const PaymentSchedulesTable: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList, operator, onError, onCardUpdateSuccess }) => {
  return (
    <Loader>
      <PaymentSchedulesTableComponent paymentSchedules={paymentSchedules} showCustomer={showCustomer} refreshList={refreshList} operator={operator} onError={onError} onCardUpdateSuccess={onCardUpdateSuccess} />
    </Loader>
  );
};
