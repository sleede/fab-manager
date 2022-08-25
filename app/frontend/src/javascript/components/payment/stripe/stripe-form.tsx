import React, { FormEvent } from 'react';
import { CardElement, useElements, useStripe } from '@stripe/react-stripe-js';
import { useTranslation } from 'react-i18next';
import { GatewayFormProps } from '../abstract-payment-modal';
import { PaymentConfirmation } from '../../../models/payment';
import StripeAPI from '../../../api/stripe';
import { Invoice } from '../../../models/invoice';
import { PaymentSchedule } from '../../../models/payment-schedule';
import CheckoutAPI from '../../../api/checkout';
import { Order } from '../../../models/order';

/**
 * A form component to collect the credit card details and to create the payment method on Stripe.
 * The form validation button must be created elsewhere, using the attribute form={formId}.
 */
export const StripeForm: React.FC<GatewayFormProps> = ({ onSubmit, onSuccess, onError, children, className, paymentSchedule = false, cart, formId, order }) => {
  const { t } = useTranslation('shared');

  const stripe = useStripe();
  const elements = useElements();

  /**
   * Handle the submission of the form. Depending on the configuration, it will create the payment method on Stripe,
   * or it will process a payment with the inputted card.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    event.stopPropagation();
    onSubmit();

    // Stripe.js has not loaded yet
    if (!stripe || !elements) { return; }

    const cardElement = elements.getElement(CardElement);
    const { error, paymentMethod } = await stripe.createPaymentMethod({
      type: 'card',
      card: cardElement
    });

    if (error) {
      // stripe error
      onError(error.message);
    } else {
      try {
        if (!paymentSchedule) {
          if (order) {
            const res = await CheckoutAPI.payment(order.token, paymentMethod.id);
            if (res.payment) {
              await handleServerConfirmation(res.payment as PaymentConfirmation);
            } else {
              res.order.total = res.order.amount;
              await handleServerConfirmation(res.order);
            }
          } else {
            // process the normal payment pipeline, including SCA validation
            const res = await StripeAPI.confirmMethod(paymentMethod.id, cart);
            await handleServerConfirmation(res);
          }
        } else {
          const res = await StripeAPI.setupSubscription(paymentMethod.id, cart);
          await handleServerConfirmation(res, paymentMethod.id);
        }
      } catch (err) {
        // catch api errors
        onError(err);
      }
    }
  };

  /**
   * Process the server response about the Strong-customer authentication (SCA)
   * @param response can be a PaymentConfirmation, or an Invoice/PaymentSchedule (if the payment succeeded)
   * @param paymentMethodId ID of the payment method, required only when confirming a payment schedule
   * @see app/controllers/api/stripe_controller.rb#confirm_payment
   */
  const handleServerConfirmation = async (response: PaymentConfirmation|Invoice|PaymentSchedule|Order, paymentMethodId?: string) => {
    if ('error' in response) {
      if (response.error.statusText) {
        onError(response.error.statusText);
      } else {
        onError(`${t('app.shared.stripe_form.payment_card_error')} ${response.error}`);
      }
    } else if ('requires_action' in response) {
      if (response.type === 'payment') {
        // Use Stripe.js to handle required card action
        const result = await stripe.handleCardAction(response.payment_intent_client_secret);
        if (result.error) {
          onError(result.error.message);
        } else {
          // The card action has been handled
          // The PaymentIntent can be confirmed again on the server
          try {
            if (order) {
              const confirmation = await CheckoutAPI.confirmPayment(order.token, result.paymentIntent.id);
              confirmation.order.total = confirmation.order.amount;
              await handleServerConfirmation(confirmation.order);
            } else {
              const confirmation = await StripeAPI.confirmIntent(result.paymentIntent.id, cart);
              await handleServerConfirmation(confirmation);
            }
          } catch (e) {
            onError(e);
          }
        }
      } else if (response.type === 'subscription') {
        const result = await stripe.confirmCardPayment(response.payment_intent_client_secret, {
          payment_method: paymentMethodId
        });
        if (result.error) {
          onError(result.error.message);
        } else {
          try {
            const confirmation = await StripeAPI.confirmSubscription(response.subscription_id, cart);
            await handleServerConfirmation(confirmation);
          } catch (e) {
            onError(e);
          }
        }
      }
    } else if ('id' in response) {
      onSuccess(response);
    } else {
      console.error(`[StripeForm] unknown response received: ${response}`);
    }
  };

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
      }
    },
    hidePostalCode: true
  };

  return (
    <form onSubmit={handleSubmit} id={formId} className={`stripe-form ${className || ''}`}>
      <CardElement options={cardOptions} />
      {children}
    </form>
  );
};
