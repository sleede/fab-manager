/**
 * This component initializes the stripe's Elements tag with the API key
 */

import React from 'react';
import { Elements } from '@stripe/react-stripe-js';
import { IApplication } from '../models/application';
import SettingAPI from '../api/setting';
import { loadStripe } from "@stripe/stripe-js";

const stripePublicKey = SettingAPI.get('stripe_public_key');

export const StripeElements: React.FC = ({ children }) => {
  const publicKey = stripePublicKey.read();
  const stripePromise = loadStripe(publicKey.value);

  return (
    <Elements stripe={stripePromise}>
      {children}
    </Elements>
  );
}
