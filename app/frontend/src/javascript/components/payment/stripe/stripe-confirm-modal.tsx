import { StripeConfirm } from './stripe-confirm';
import { FabModal } from '../../base/fab-modal';
import React, { useEffect, useState } from 'react';
import PaymentScheduleAPI from '../../../api/payment-schedule';
import { PaymentScheduleItem } from '../../../models/payment-schedule';
import { useTranslation } from 'react-i18next';

interface StripeConfirmModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: () => void,
  paymentScheduleItemId: number,
}

/**
 * Modal dialog that trigger a 3D secure confirmation for the given payment schedule item (deadline for a payment schedule).
 */
export const StripeConfirmModal: React.FC<StripeConfirmModalProps> = ({ isOpen, toggleModal, onSuccess, paymentScheduleItemId }) => {
  const { t } = useTranslation('shared');

  const [item, setItem] = useState<PaymentScheduleItem>(null);
  const [isPending, setIsPending] = useState(false);

  useEffect(() => {
    PaymentScheduleAPI.getItem(paymentScheduleItemId).then(data => {
      setItem(data);
    });
  }, [paymentScheduleItemId]);

  /**
   * Callback triggered when the confirm button was clicked in the modal.
   */
  const onConfirmed = (): void => {
    togglePending();
    onSuccess();
  };

  /**
   * Enable/disable the confirm button of the "action" modal
   */
  const togglePending = (): void => {
    setIsPending(!isPending);
  };

  return (
    <FabModal title={t('app.shared.stripe_confirm_modal.resolve_action')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      onConfirm={onConfirmed}
      confirmButton={t('app.shared.stripe_confirm_modal.ok_button')}
      preventConfirm={isPending}>
      {item && <StripeConfirm clientSecret={item.client_secret} onResponse={togglePending} />}
    </FabModal>
  );
};
