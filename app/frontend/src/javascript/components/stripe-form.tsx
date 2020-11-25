import React, { FormEvent } from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { PaymentMethod } from "@stripe/stripe-js";

interface StripeFormProps {
  onSubmit: () => void,
  onSuccess: (paymentMethod: PaymentMethod) => void,
  onError: (message: string) => void,
}

export const StripeForm: React.FC<StripeFormProps> = ({ onSubmit, onSuccess, onError, children }) => {

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
      onSuccess(paymentMethod);
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
    <form onSubmit={handleSubmit} id="stripe-form">
      <CardElement options={cardOptions} />
      {children}
    </form>
  );
}
