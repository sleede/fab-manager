import React, { useEffect, useState } from 'react';
import { useStripe } from '@stripe/react-stripe-js';
import { useTranslation } from 'react-i18next';

interface StripeConfirmProps {
  clientSecret: string,
  onResponse: () => void,
}

export const StripeConfirm: React.FC<StripeConfirmProps> = ({ clientSecret, onResponse }) => {
  const stripe = useStripe();
  const { t } = useTranslation('shared');

  const [message, setMessage] = useState<string>(t('app.shared.stripe_confirm.pending'));
  const [type, setType] = useState<string>('info');

  useEffect(() => {
    stripe.confirmCardPayment(clientSecret).then(function(result) {
      onResponse();
      if (result.error) {
        // Display error.message in your UI.
        setType('error');
        setMessage(result.error.message);
      } else {
        // The setup has succeeded. Display a success message.
        setType('success');
        setMessage(t('app.shared.stripe_confirm.success'));
      }
    });
  }, [])
  return <div className="stripe-confirm">
    <div className={`message--${type}`}><span className="message-text">{message}</span></div>
  </div>;
}
