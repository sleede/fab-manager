/**
 * This component enables the user to input his card data.
 */

import React, { ChangeEvent, FormEvent, ReactNode, useState } from 'react';
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
import CustomAssetAPI from '../api/custom-asset';
import { CustomAssetName } from '../models/custom-asset';
import { PaymentSchedule } from '../models/payment-schedule';
import { IFablab } from '../models/fablab';

declare var Application: IApplication;
declare var Fablab: IFablab;

interface StripeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (paymentMethod: PaymentMethod) => void,
  reservation: Reservation,
  currentUser: User,
  wallet: Wallet,
  price: number,
  remainingPrice: number,
  schedule: PaymentSchedule
}

const cgvFile = CustomAssetAPI.get(CustomAssetName.CgvFile);

const StripeModal: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, reservation, currentUser, wallet, price, remainingPrice, schedule }) => {

  const stripe = useStripe();
  const elements = useElements();
  const { t } = useTranslation('shared');

  const cgv = cgvFile.read();

  const [errors, setErrors] = useState(null);
  const [submitState, setSubmitState] = useState(false);
  const [tos, setTos] = useState(false);

  /**
   * Handle the submission of the form. Depending on the configuration, it will create the payment method on Stripe,
   * or it will process a payment with the inputted card.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    setSubmitState(true);

    // Stripe.js has not loaded yet
    if (!stripe || !elements) { return; }

    const cardElement = elements.getElement(CardElement);
    const { error, paymentMethod } = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    setSubmitState(false);
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
   * Check if the Terms of Sales document is set
   */
  const hasCgv = (): boolean => {
    return cgv != null;
  }

  const toggleTos = (event: ChangeEvent): void => {
    setTos(!tos);
  }

  /**
   * Check if we are currently creating a payment schedule
   */
  const isPaymentSchedule = (): boolean => {
    return schedule !== undefined;
  }

  /**
   * Return the formatted localized amount for the given price (eg. 20.5 => "20,50 €")
   */
  const formatPrice = (amount: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(amount);
  }

  /**
   * Return the form submission button. This button will be shown into the modal footer.
   */
  const submitButton = (): ReactNode => {
    return (
      <button type="submit"
              onClick={toggleSubmitButton}
              disabled={submitState}
              form="stripe-form"
              className="validate-btn">
        {t('app.shared.stripe.confirm_payment_of_', { AMOUNT: formatPrice(remainingPrice) })}
      </button>
    );
  }

  /**
   * Options for the Stripe's card input
   */
  const cardOptions = {
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
  };

  return (
    <div className="stripe-modal">
      <FabModal title={t('app.shared.stripe.online_payment')} isOpen={isOpen} toggleModal={toggleModal} confirmButton={submitButton()}>
        <StripeElements>
          <form onSubmit={handleSubmit} id="stripe-form">
            <WalletInfo reservation={reservation} currentUser={currentUser} wallet={wallet} price={price} remainingPrice={remainingPrice} />
            <CardElement options={cardOptions} />
          </form>
        </StripeElements>
        {hasErrors() && <div className="stripe-errors">
          {errors}
        </div>}
        {hasCgv() && <div className="terms-of-sales">
          <input type="checkbox" id="acceptToS" name="acceptCondition" checked={tos} onChange={toggleTos} required />
        </div>}
        {isPaymentSchedule() && <div className="payment-schedule-info">
          <p>{ t('app.shared.stripe.payment_schedule', { DEADLINES: schedule.items.length }) }</p>
        </div>}
        <div className="stripe-modal-icons">
          <i className="fa fa-lock fa-2x m-r-sm pos-rlt" />
          <img src="../../../images/powered_by_stripe.png" alt="powered by stripe" />
          <img src="../../../images/mastercard.png" alt="mastercard" />
          <img src="../../../images/visa.png" alt="visa" />
        </div>
      </FabModal>
    </div>
  );
}

const StripeModalWrapper: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, reservation, currentUser, wallet, price, remainingPrice, schedule }) => {
  return (
    <Loader>
      <StripeModal isOpen={isOpen} toggleModal={toggleModal} afterSuccess={afterSuccess} reservation={reservation} currentUser={currentUser} wallet={wallet} price={price} remainingPrice={remainingPrice} schedule={schedule} />
    </Loader>
  );
}

Application.Components.component('stripeModal', react2angular(StripeModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess', 'reservation', 'currentUser', 'wallet', 'price', 'remainingPrice', 'schedule']));
