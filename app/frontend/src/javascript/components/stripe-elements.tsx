/**
 * This component initializes the stripe's Elements tag with the API key
 */

import React, { memo } from 'react';
import { Elements } from '@stripe/react-stripe-js';
import { loadStripe } from "@stripe/stripe-js";
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';

const stripePublicKey = SettingAPI.get(SettingName.StripePublicKey);

export const StripeElements: React.FC = memo(({ children }) => {
  const publicKey = stripePublicKey.read();
  const stripePromise = loadStripe(publicKey.value);

  return (
    <Elements stripe={stripePromise}>
      {children}
    </Elements>
  );
})
