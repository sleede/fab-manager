/**
 * This component enables the user to type his card data.
 */

import React from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { react2angular } from 'react2angular';
import { Loader } from './loader';
import { IApplication } from '../models/application';


declare var Application: IApplication;

const StripeCard: React.FC = () => {

  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (event) => {
    event.preventDefault();

    // Stripe.js has not loaded yet
    if (!stripe || !elements) { return; }

    const cardElement = elements.getElement(CardElement);

    const { error, paymentMethod } = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement,
    });

    if (error) {
      console.log('[error]', error);
    } else {
      console.log('[PaymentMethod]', paymentMethod);
    }

  }

  return (
    <div className="stripe-card">
      <form onSubmit={handleSubmit}>
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
          }}
        />
      </form>
    </div>
  );
}

const StripeCardWrapper: React.FC = () => {
  return (
    <Loader>
      <StripeCard />
    </Loader>
  );
}

Application.Components.component('stripeCard', react2angular(StripeCardWrapper));
