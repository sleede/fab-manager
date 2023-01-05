import { ReactElement, useEffect, useState } from 'react';
import * as React from 'react';
import { Loader } from '../base/loader';
import { StripeCardUpdateModal } from './stripe/stripe-card-update-modal';
import { PayzenCardUpdateModal } from './payzen/payzen-card-update-modal';
import { User } from '../../models/user';
import { PaymentSchedule } from '../../models/payment-schedule';
import { useTranslation } from 'react-i18next';

interface UpdateCardModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: () => void,
  onError: (message: string) => void,
  schedule: PaymentSchedule,
  operator: User
}

/**
 * This component open a modal dialog for the configured payment gateway, allowing the user to input his card data
 * to process an online payment.
 */
const UpdateCardModal: React.FC<UpdateCardModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, operator, schedule }) => {
  const { t } = useTranslation('shared');
  const [gateway, setGateway] = useState<string>('');

  useEffect(() => {
    setGateway(schedule.gateway);
  }, [schedule]);

  /**
   * Render the Stripe update-card modal
   */
  const renderStripeModal = (): ReactElement => {
    return <StripeCardUpdateModal isOpen={isOpen}
      toggleModal={toggleModal}
      onSuccess={afterSuccess}
      operator={operator}
      schedule={schedule} />;
  };

  /**
   * Render the PayZen update-card modal
   */
  const renderPayZenModal = (): ReactElement => {
    return <PayzenCardUpdateModal isOpen={isOpen}
      toggleModal={toggleModal}
      onSuccess={afterSuccess}
      operator={operator}
      schedule={schedule} />;
  };

  /**
   * Determine which gateway is in use with the current schedule and return the appropriate modal
   */

  switch (gateway) {
    case 'Stripe':
      return renderStripeModal();
    case 'PayZen':
      return renderPayZenModal();
    case '':
    case undefined:
      return <div/>;
    default:
      onError(t('app.shared.update_card_modal.unexpected_error'));
      console.error(`[UpdateCardModal] unexpected gateway: ${schedule.gateway} for schedule ${schedule.id}`);
      return <div />;
  }
};

const UpdateCardModalWrapper: React.FC<UpdateCardModalProps> = (props) => {
  return (
    <Loader>
      <UpdateCardModal {...props} />
    </Loader>
  );
};

export { UpdateCardModalWrapper as UpdateCardModal };
