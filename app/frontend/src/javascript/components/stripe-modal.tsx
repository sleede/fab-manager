/**
 * This component enables the user to input his card data.
 */

import React, { ChangeEvent, ReactNode, useEffect, useState } from 'react';
import { react2angular } from 'react2angular';
import { Loader } from './loader';
import { IApplication } from '../models/application';
import { StripeElements } from './stripe-elements';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from './fab-modal';
import { PaymentMethod } from '@stripe/stripe-js';
import { WalletInfo } from './wallet-info';
import { Reservation } from '../models/reservation';
import { User } from '../models/user';
import { Wallet } from '../models/wallet';
import CustomAssetAPI from '../api/custom-asset';
import { CustomAssetName } from '../models/custom-asset';
import { PaymentSchedule } from '../models/payment-schedule';
import { IFablab } from '../models/fablab';
import WalletLib from '../lib/wallet';
import { StripeForm } from './stripe-form';

import stripeLogo from '../../../images/powered_by_stripe.png';
import mastercardLogo from '../../../images/mastercard.png';
import visaLogo from '../../../images/visa.png';

declare var Application: IApplication;
declare var Fablab: IFablab;

interface StripeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (paymentMethod: PaymentMethod) => void,
  reservation: Reservation,
  currentUser: User,
  wallet: Wallet,
  price: number,
  schedule: PaymentSchedule
}

const cgvFile = CustomAssetAPI.get(CustomAssetName.CgvFile);

const StripeModal: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, reservation, currentUser, wallet, price, schedule }) => {
  const [remainingPrice, setRemainingPrice] = useState(0);

  /**
   * Refresh the remaining price on each display
   */
  useEffect(() => {
    const wLib = new WalletLib(wallet);
    setRemainingPrice(wLib.computeRemainingPrice(price));
  })

  const { t } = useTranslation('shared');

  const cgv = cgvFile.read();

  const [errors, setErrors] = useState(null);
  const [submitState, setSubmitState] = useState(false);
  const [tos, setTos] = useState(false);

  /**
   * Check if there is currently an error to display
   */
  const hasErrors = (): boolean => {
    return errors !== null;
  }

  /**
   * Check if the Terms of Sales document is set
   */
  const hasCgv = (): boolean => {
    return cgv != null;
  }

  const toggleTos = (event: ChangeEvent): void => {
    setTos(!tos);
  }

  /**
   * Check if we are currently creating a payment schedule
   */
  const isPaymentSchedule = (): boolean => {
    return schedule !== undefined;
  }

  /**
   * Return the formatted localized amount for the given price (eg. 20.5 => "20,50 €")
   */
  const formatPrice = (amount: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(amount);
  }

  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="stripe-modal-icons">
        <i className="fa fa-lock fa-2x m-r-sm pos-rlt" />
        <img src={stripeLogo} alt="powered by stripe" />
        <img src={mastercardLogo} alt="mastercard" />
        <img src={visaLogo} alt="visa" />
      </div>
    );
  }

  const handleSubmit = (): void => {
    setSubmitState(true);
  }

  const handleFormSuccess = (paymentMethod: PaymentMethod): void => {
    setSubmitState(false);
    afterSuccess(paymentMethod);
  }

  const handleFormError = (message: string): void => {
    setSubmitState(false);
    setErrors(message);
  }


  return (
    <FabModal title={t('app.shared.stripe.online_payment')}
              isOpen={isOpen}
              toggleModal={toggleModal}
              width={ModalSize.medium}
              closeButton={false}
              customFooter={logoFooter()}
              className="stripe-modal">
      <WalletInfo reservation={reservation} currentUser={currentUser} wallet={wallet} price={price} />
      <StripeElements>
        <StripeForm onSubmit={handleSubmit} onSuccess={handleFormSuccess} onError={handleFormError} className="stripe-form">
          {hasErrors() && <div className="stripe-errors">
            {errors}
          </div>}
          {hasCgv() && <div className="terms-of-sales">
            <input type="checkbox" id="acceptToS" name="acceptCondition" checked={tos} onChange={toggleTos} required />
            <label htmlFor="acceptToS">{ t('app.shared.stripe.i_have_read_and_accept_') }
              <a href={cgv.custom_asset_file_attributes.attachment_url} target="_blank">
                { t('app.shared.stripe._the_general_terms_and_conditions') }
              </a>
            </label>
          </div>}
          {isPaymentSchedule() && <div className="payment-schedule-info">
            <i className="fa fa-warning" />
            <p>{ t('app.shared.stripe.payment_schedule', { DEADLINES: schedule.items.length }) }</p>
          </div>}
        </StripeForm>
        <button type="submit"
                disabled={submitState}
                form="stripe-form"
                className="validate-btn">
          {t('app.shared.stripe.confirm_payment_of_', { AMOUNT: formatPrice(remainingPrice) })}
        </button>
      </StripeElements>
    </FabModal>
  );
}

const StripeModalWrapper: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, reservation, currentUser, wallet, price, schedule }) => {
  return (
    <Loader>
      <StripeModal isOpen={isOpen} toggleModal={toggleModal} afterSuccess={afterSuccess} reservation={reservation} currentUser={currentUser} wallet={wallet} price={price} schedule={schedule} />
    </Loader>
  );
}

Application.Components.component('stripeModal', react2angular(StripeModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess', 'reservation', 'currentUser', 'wallet', 'price', 'schedule']));
