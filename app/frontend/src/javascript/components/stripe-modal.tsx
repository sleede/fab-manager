/**
 * This component enables the user to type his card data.
 */

import React, { FormEvent, ReactNode, useState } from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { react2angular } from 'react2angular';
import { Loader } from './loader';
import { IApplication } from '../models/application';
import { StripeElements } from './stripe-elements';
import { useTranslation } from 'react-i18next';
import { FabModal } from './fab-modal';
import { PaymentMethod } from '@stripe/stripe-js';
import { WalletInfo } from './wallet-info';
import { Reservation } from '../models/reservation';
import { User } from '../models/user';
import { Wallet } from '../models/wallet';

declare var Application: IApplication;

interface StripeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (paymentMethod: PaymentMethod) => void,
  reservation: Reservation,
  currentUser: User,
  wallet: Wallet,
  price: number,
  remainingPrice: number,
}

const StripeModal: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, reservation, currentUser, wallet, price, remainingPrice }) => {

  const stripe = useStripe();
  const elements = useElements();
  const { t } = useTranslation('shared');

  const [errors, setErrors] = useState(null);
  const [submitState, setSubmitState] = useState(false);

  /**
   * Handle the submission of the form. Depending on the configuration, it will create the payment method on stripe,
   * or it will process a payment with the inputted card.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();

    // Stripe.js has not loaded yet
    if (!stripe || !elements) { return; }

    const cardElement = elements.getElement(CardElement);
    const { error, paymentMethod } = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    if (error) {
      setErrors(error.message);
    } else {
      setErrors(null);
      afterSuccess(paymentMethod);
    }
  }

  /**
   * Check if there is currently an error to display
   */
  const hasErrors = (): boolean => {
    return errors !== null;
  }

  /**
   * Change the state of the submit button: enabled/disabled
   */
  const toggleSubmitButton = (): void => {
    setSubmitState(!submitState);
  }

  /**
   * Return the form submission button. This button will be shown into the modal footer
   */
  const submitButton = (): ReactNode => {
    return (
      <button type="submit"
              onClick={toggleSubmitButton}
              disabled={submitState}
              form="stripe-form"
              className="validate-btn">
        {t('app.shared.buttons.confirm')}
      </button>
    );
  }

  return (
    <div className="stripe-modal">
      <FabModal title={t('app.shared.stripe.online_payment')} isOpen={isOpen} toggleModal={toggleModal} confirmButton={submitButton()}>
        <StripeElements>
          <form onSubmit={handleSubmit} id="stripe-form">
            <WalletInfo reservation={reservation} currentUser={currentUser} wallet={wallet} price={price} remainingPrice={remainingPrice} />
            <CardElement
              options={{
                style: {
                  base: {
                    fontSize: '16px',
                    color: '#424770',
                    '::placeholder': { color: '#aab7c4' }
                  },
                  invalid: {
                    color: '#9e2146',
                    iconColor: '#9e2146'
                  },
                },
                hidePostalCode: true
              }}
            />
          </form>
        </StripeElements>
        {hasErrors() && <div className="stripe-errors">
          {errors}
        </div>}
      </FabModal>
    </div>
  );
}

const StripeModalWrapper: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, reservation, currentUser, wallet, price, remainingPrice  }) => {
  return (
    <Loader>
      <StripeModal isOpen={isOpen} toggleModal={toggleModal} afterSuccess={afterSuccess} reservation={reservation} currentUser={currentUser} wallet={wallet} price={price} remainingPrice={remainingPrice} />
    </Loader>
  );
}

Application.Components.component('stripeModal', react2angular(StripeModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess', 'reservation', 'currentUser', 'wallet', 'price', 'remainingPrice']));
