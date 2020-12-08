import React, { FormEvent } from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { PaymentIntent } from "@stripe/stripe-js";
import PaymentAPI from '../api/payment';
import { CartItems, PaymentConfirmation } from '../models/payment';
import { useTranslation } from 'react-i18next';
import { User } from '../models/user';

interface StripeFormProps {
  onSubmit: () => void,
  onSuccess: (result: PaymentIntent|PaymentConfirmation|any) => void,
  onError: (message: string) => void,
  customer: User,
  className?: string,
  processPayment?: boolean,
  cartItems?: CartItems
}

/**
 * A form component to collect the credit card details and to create the payment method on Stripe.
 * The form validation button must be created elsewhere, using the attribute form="stripe-form".
 */
export const StripeForm: React.FC<StripeFormProps> = ({ onSubmit, onSuccess, onError, children, className, processPayment = true, cartItems, customer }) => {

  const { t } = useTranslation('shared');

  const stripe = useStripe();
  const elements = useElements();

  /**
   * Handle the submission of the form. Depending on the configuration, it will create the payment method on Stripe,
   * or it will process a payment with the inputted card.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    onSubmit();

    // Stripe.js has not loaded yet
    if (!stripe || !elements) { return; }

    const cardElement = elements.getElement(CardElement);
    const { error, paymentMethod } = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    if (error) {
      onError(error.message);
    } else {
      if (processPayment) {
        // process the full payment pipeline, including SCA validation
        const res = await PaymentAPI.confirm(paymentMethod.id, cartItems);
        await handleServerConfirmation(res);
      } else {
        // we don't want to process the payment, only associate the payment method with the user
        const { client_secret } = await PaymentAPI.setupIntent(customer.id);
        const { setupIntent, error } = await stripe.confirmCardSetup(client_secret, {
          payment_method: paymentMethod.id
        })
        if (error) {
          onError(error.message);
        } else {
          if (setupIntent.status === 'succeeded') {
            onSuccess(setupIntent);
          }
        }
      }
    }
  }

  /**
   * Process the server response about the Strong-customer authentication (SCA)
   * @param response can be a PaymentConfirmation, or a Reservation (if the reservation succeeded), or a Subscription (if the subscription succeeded)
   * @see app/controllers/api/payments_controller.rb#on_reservation_success
   * @see app/controllers/api/payments_controller.rb#on_subscription_success
   * @see app/controllers/api/payments_controller.rb#generate_payment_response
   */
  const handleServerConfirmation = async (response: PaymentConfirmation|any) => {
    if (response.error) {
      if (response.error.statusText) {
        onError(response.error.statusText);
      } else {
        onError(`${t('app.shared.messages.payment_card_error')} ${response.error}`);
      }
    } else if (response.requires_action) {
      // Use Stripe.js to handle required card action
      const result = await stripe.handleCardAction(response.payment_intent_client_secret);
      if (result.error) {
        onError(result.error.message);
      } else {
        // The card action has been handled
        // The PaymentIntent can be confirmed again on the server
        try {
          const confirmation = await PaymentAPI.confirm(result.paymentIntent.id, cartItems);
          await handleServerConfirmation(confirmation);
        } catch (e) {
          onError(e);
        }
      }
    } else {
      onSuccess(response);
    }
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
    <form onSubmit={handleSubmit} id="stripe-form" className={className}>
      <CardElement options={cardOptions} />
      {children}
    </form>
  );
}
