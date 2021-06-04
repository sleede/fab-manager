import React, { ReactElement, useEffect, useState } from 'react';
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
const UpdateCardModalComponent: React.FC<UpdateCardModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, operator, schedule }) => {
  const { t } = useTranslation('shared');
  const [gateway, setGateway] = useState<string>('');

  useEffect(() => {
    if (schedule.gateway_subscription.classname.match(/^PayZen::/)) {
      setGateway('payzen');
    } else if (schedule.gateway_subscription.classname.match(/^Stripe::/)) {
      setGateway('stripe');
    }
  }, [schedule]);

  /**
   * Render the Stripe update-card modal
   */
  const renderStripeModal = (): ReactElement => {
    return <StripeCardUpdateModal isOpen={isOpen}
                                  toggleModal={toggleModal}
                                  onSuccess={afterSuccess}
                                  operator={operator}
                                  schedule={schedule} />
  }

  /**
   * Render the PayZen update-card modal
   */ // 1
  const renderPayZenModal = (): ReactElement => {
    return <PayzenCardUpdateModal isOpen={isOpen}
                                  toggleModal={toggleModal}
                                  onSuccess={afterSuccess}
                                  operator={operator}
                                  schedule={schedule} />
  }

  /**
   * Determine which gateway is in use with the current schedule and return the appropriate modal
   */

  switch (gateway) {
    case 'stripe':
      return renderStripeModal();
    case 'payzen':
      return renderPayZenModal();
    case '':
      return <div/>;
    default:
      onError(t('app.shared.update_card_modal.unexpected_error'));
      console.error(`[UpdateCardModal] unexpected gateway: ${schedule.gateway_subscription?.classname}`);
      return <div />;
  }
}


export const UpdateCardModal: React.FC<UpdateCardModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, operator, schedule }) => {
  return (
    <Loader>
      <UpdateCardModalComponent isOpen={isOpen} toggleModal={toggleModal} afterSuccess={afterSuccess} onError={onError} operator={operator} schedule={schedule} />
    </Loader>
  );
}
