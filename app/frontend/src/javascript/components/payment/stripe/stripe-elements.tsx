import React, { memo, useEffect, useState } from 'react';
import { Elements } from '@stripe/react-stripe-js';
import { loadStripe, Stripe } from '@stripe/stripe-js';
import { SettingName } from '../../../models/setting';
import SettingAPI from '../../../api/setting';

/**
 * This component initializes the stripe's Elements tag with the API key
 */
export const StripeElements: React.FC = memo(({ children }) => {
  const [stripe, setStripe] = useState<Promise<Stripe | null>>(undefined);

  /**
   * When this component is mounted, we initialize the <Elements> tag with the Stripe's public key
   */
  useEffect(() => {
    SettingAPI.get(SettingName.StripePublicKey).then(key => {
      if (key?.value) {
        const promise = loadStripe(key.value);
        setStripe(promise);
      }
    });
  }, []);

  return (
    <div>
      {stripe && <Elements stripe={stripe}>
        {children}
      </Elements>}
      {!stripe && children}
    </div>
  );
});

StripeElements.displayName = 'StripeElements';
