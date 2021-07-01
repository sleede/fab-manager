import React, { ReactNode, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../../base/fab-modal';
import { StripeCardUpdate } from './stripe-card-update';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';
import stripeLogo from '../../../../../images/powered_by_stripe.png';
import mastercardLogo from '../../../../../images/mastercard.png';
import visaLogo from '../../../../../images/visa.png';

interface StripeCardUpdateModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: () => void,
  schedule: PaymentSchedule,
  operator: User
}

export const StripeCardUpdateModal: React.FC<StripeCardUpdateModalProps> = ({ isOpen, toggleModal, onSuccess, schedule, operator }) => {
  const { t } = useTranslation('shared');

  // prevent submitting the form to update the card details, until the user has filled correctly all required fields
  const [canSubmitUpdateCard, setCanSubmitUpdateCard] = useState<boolean>(true);
  // we save errors here, if any, for display purposes.
  const [errors, setErrors] = useState<string>(null);

  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="stripe-modal-icons">
        <i className="fa fa-lock fa-2x m-r-sm pos-rlt" />
        <img src={stripeLogo} alt="powered by stripe" />
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
    <FabModal title={t('app.shared.stripe_card_update_modal.update_card')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={false}
      customFooter={logoFooter()}
      className="stripe-update-card-modal">
      {schedule && <StripeCardUpdate onSubmit={handleCardUpdateSubmit}
        onSuccess={onSuccess}
        onError={handleCardUpdateError}
        schedule={schedule}
        operator={operator}
        className="card-form" >
        {errors && <div className="stripe-errors">
          {errors}
        </div>}
      </StripeCardUpdate>}
      <div className="submit-card">
        {canSubmitUpdateCard && <button type="submit" disabled={!canSubmitUpdateCard} form="stripe-card" className="submit-card-btn">{t('app.shared.stripe_card_update_modal.validate_button')}</button>}
        {!canSubmitUpdateCard && <div className="payment-pending">
          <div className="fa-2x">
            <i className="fas fa-circle-notch fa-spin" />
          </div>
        </div>}
      </div>
    </FabModal>
  );
};
