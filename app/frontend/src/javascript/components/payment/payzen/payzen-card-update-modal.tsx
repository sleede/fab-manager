import React, { ReactNode, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../../base/fab-modal';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';
import mastercardLogo from '../../../../../images/mastercard.png';
import visaLogo from '../../../../../images/visa.png';
import payzenLogo from '../../../../../images/payzen-secure.png';
import { PayzenForm } from './payzen-form';

interface PayzenCardUpdateModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: () => void,
  schedule: PaymentSchedule,
  operator: User
}

/**
 * Modal dialog to allow the member to update his payment card for a payment schedule, when the PayZen gateway is used
 */
export const PayzenCardUpdateModal: React.FC<PayzenCardUpdateModalProps> = ({ isOpen, toggleModal, onSuccess, schedule, operator }) => {
  const { t } = useTranslation('shared');

  // prevent submitting the form to update the card details, until the user has filled correctly all required fields
  const [canSubmitUpdateCard, setCanSubmitUpdateCard] = useState<boolean>(true);
  // we save errors here, if any, for display purposes.
  const [errors, setErrors] = useState<string>(null);

  // the unique identifier of the html form
  const formId = 'payzen-card';

  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="payzen-modal-icons">
        <img src={payzenLogo} alt="powered by PayZen" />
        <img src={mastercardLogo} alt="mastercard" />
        <img src={visaLogo} alt="visa" />
      </div>
    );
  };

  /**
   * When the user clicks the submit button, we disable it to prevent double form submission
   */
  const handleCardUpdateSubmit = (): void => {
    setCanSubmitUpdateCard(false);
  };

  /**
   * When the card was not updated, show the error
   */
  const handleCardUpdateError = (error): void => {
    setErrors(error);
    setCanSubmitUpdateCard(true);
  };

  return (
    <FabModal title={t('app.shared.payzen_card_update_modal.update_card')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={false}
      customFooter={logoFooter()}
      className="payzen-card-update-modal">
      {schedule && <PayzenForm onSubmit={handleCardUpdateSubmit}
        onSuccess={onSuccess}
        onError={handleCardUpdateError}
        className="card-form"
        paymentSchedule={schedule}
        operator={operator}
        customer={schedule.user as User}
        updateCard={true}
        formId={formId} >
        {errors && <div className="payzen-errors">
          {errors}
        </div>}
      </PayzenForm>}
      <div className="submit-card">
        {canSubmitUpdateCard && <button type="submit" disabled={!canSubmitUpdateCard} form={formId} className="submit-card-btn">{t('app.shared.payzen_card_update_modal.validate_button')}</button>}
        {!canSubmitUpdateCard && <div className="payment-pending">
          <div className="fa-2x">
            <i className="fas fa-circle-notch fa-spin" />
          </div>
        </div>}
      </div>
    </FabModal>
  );
};
