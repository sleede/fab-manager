/**
 * This component initializes the stripe's Elements tag with the API key
 */

import React, { memo, useEffect, useState } from 'react';
import { Elements } from '@stripe/react-stripe-js';
import { loadStripe } from "@stripe/stripe-js";
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';

const stripePublicKey = SettingAPI.get(SettingName.StripePublicKey);

export const StripeElements: React.FC = memo(({ children }) => {
  const [stripe, setStripe] = useState(undefined);

  useEffect(() => {
    const key = stripePublicKey.read();
    const promise = loadStripe(key.value);
    setStripe(promise);
  }, [])

  return (
    <div>
      {stripe && <Elements stripe={stripe}>
        {children}
      </Elements>}
    </div>
  );
})
