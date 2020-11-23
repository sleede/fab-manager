/**
 * This is a compatibility wrapper to allow usage of stripe.js Elements inside of the angular.js app
 */

import React from 'react';
import { Elements } from '@stripe/react-stripe-js';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import SettingAPI from '../../api/setting';
import { loadStripe } from "@stripe/stripe-js";

declare var Application: IApplication;
const stripePublicKey = SettingAPI.get('stripe_public_key');

const ElementsWrapper: React.FC = () => {
  const publicKey = stripePublicKey.read();
  const stripePromise = loadStripe(publicKey.value);

  return (
    <Elements stripe={stripePromise} />
  );
}

Application.Components.component('stripeElements', react2angular(ElementsWrapper));
