import React from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { PaymentMethod, PaymentSchedule } from '../../models/payment-schedule';
import PaymentScheduleAPI from '../../api/payment-schedule';

interface UpdatePaymentMeanModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onError: (message: string) => void,
  afterSuccess: () => void,
  paymentSchedule: PaymentSchedule
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: PaymentMethod, label: string };

export const UpdatePaymentMeanModal: React.FC<UpdatePaymentMeanModalProps> = ({ isOpen, toggleModal, onError, afterSuccess, paymentSchedule }) => {
  const { t } = useTranslation('admin');

  const [paymentMean, setPaymentMean] = React.useState<PaymentMethod>();

  /**
   * Convert all payment means to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return Object.keys(PaymentMethod).filter(pm => PaymentMethod[pm] !== PaymentMethod.Card).map(pm => {
      return { value: PaymentMethod[pm], label: t(`app.admin.update_payment_mean_modal.method_${pm}`) };
    });
  };

  /**
   * When the payment mean is changed in the select, update the state
   */
  const handleMeanSelected = (option: selectOption): void => {
    setPaymentMean(option.value);
  };

  /**
   * When the user clicks on the update button, update the default payment mean for the given payment schedule
   */
  const handlePaymentMeanUpdate = (): void => {
    PaymentScheduleAPI.update({
      id: paymentSchedule.id,
      payment_method: paymentMean
    }).then(() => {
      afterSuccess();
    }).catch(error => {
      onError(error.message);
    });
  };

  return (
    <FabModal isOpen={isOpen}
      className="update-payment-mean-modal"
      title={t('app.admin.update_payment_mean_modal.title')}
      confirmButton={t('app.admin.update_payment_mean_modal.confirm_button')}
      onConfirm={handlePaymentMeanUpdate}
      toggleModal={toggleModal}
      closeButton={true}>
      <span>{t('app.admin.update_payment_mean_modal.update_info')}</span>
      <Select className="payment-mean-select"
        placeholder={t('app.admin.update_payment_mean_modal.select_payment_mean')}
        id="payment-mean"
        onChange={handleMeanSelected}
        options={buildOptions()}></Select>
    </FabModal>
  );
};