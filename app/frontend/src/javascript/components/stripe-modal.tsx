import React, { ReactNode, useEffect, useState } from 'react';
import { react2angular } from 'react2angular';
import { Loader } from './base/loader';
import { IApplication } from '../models/application';
import { StripeElements } from './stripe-elements';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from './base/fab-modal';
import { SetupIntent } from '@stripe/stripe-js';
import { WalletInfo } from './wallet-info';
import { User } from '../models/user';
import CustomAssetAPI from '../api/custom-asset';
import { CustomAssetName } from '../models/custom-asset';
import { PaymentSchedule } from '../models/payment-schedule';
import { IFablab } from '../models/fablab';
import WalletLib from '../lib/wallet';
import { StripeForm } from './stripe-form';
import { CartItems, PaymentConfirmation } from '../models/payment';
import WalletAPI from '../api/wallet';
import PriceAPI from '../api/price';
import { HtmlTranslate } from './base/html-translate';

import stripeLogo from '../../../images/powered_by_stripe.png';
import mastercardLogo from '../../../images/mastercard.png';
import visaLogo from '../../../images/visa.png';

declare var Application: IApplication;
declare var Fablab: IFablab;

interface StripeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: SetupIntent|PaymentConfirmation) => void,
  cartItems: CartItems,
  currentUser: User,
  schedule: PaymentSchedule,
  customer: User
}

// initial request to the API
const cgvFile = CustomAssetAPI.get(CustomAssetName.CgvFile);

/**
 * This component enables the user to input his card data or process payments.
 * Supports Strong-Customer Authentication (SCA).
 */
const StripeModal: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, cartItems, currentUser, schedule, customer }) => {
  // customer's wallet
  const [wallet, setWallet] = useState(null);
  // server-computed price with all details
  const [price, setPrice] = useState(null);
  // remaining price = total price - wallet amount
  const [remainingPrice, setRemainingPrice] = useState(0);
  // is the component ready to display?
  const [ready, setReady] = useState(false);
  // errors to display in the UI (stripe errors mainly)
  const [errors, setErrors] = useState(null);
  // are we currently processing the payment (ie. the form was submit, but the process is still running)?
  const [submitState, setSubmitState] = useState(false);
  // did the user accepts the terms of services (CGV)?
  const [tos, setTos] = useState(false);

  const { t } = useTranslation('shared');
  const cgv = cgvFile.read();


  /**
   * On each display:
   * - Refresh the wallet
   * - Refresh the price
   * - Refresh the remaining price
   */
  useEffect(() => {
    if (!cartItems) return;
    WalletAPI.getByUser(cartItems.reservation?.user_id || cartItems.subscription?.user_id).then((wallet) => {
      setWallet(wallet);
      PriceAPI.compute(cartItems).then((res) => {
        setPrice(res);
        const wLib = new WalletLib(wallet);
        setRemainingPrice(wLib.computeRemainingPrice(res.price));
        setReady(true);
      })
    })
  }, [cartItems]);

  /**
   * Check if there is currently an error to display
   */
  const hasErrors = (): boolean => {
    return errors !== null;
  }

  /**
   * Check if the user accepts the Terms of Sales document
   */
  const hasCgv = (): boolean => {
    return cgv != null;
  }

  /**
   * Triggered when the user accepts or declines the Terms of Sales
   */
  const toggleTos = (): void => {
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

  /**
   * Set the component as 'currently submitting'
   */
  const handleSubmit = (): void => {
    setSubmitState(true);
  }

  /**
   * After sending the form with success, process the resulting payment method
   */
  const handleFormSuccess = async (result: SetupIntent|PaymentConfirmation|any): Promise<void> => {
    setSubmitState(false);
    afterSuccess(result);
  }

  /**
   * When stripe-form raise an error, it is handled by this callback which display it in the modal.
   */
  const handleFormError = (message: string): void => {
    setSubmitState(false);
    setErrors(message);
  }

  /**
   * Check the form can be submitted.
   * => We're not currently already submitting the form, and, if the terms of service are enabled, the user agrees with them.
   */
  const canSubmit = (): boolean => {
    let terms = true;
    if (hasCgv()) { terms = tos; }
    return !submitState && terms;
  }


  return (
    <FabModal title={t('app.shared.stripe.online_payment')}
              isOpen={isOpen}
              toggleModal={toggleModal}
              width={ModalSize.medium}
              closeButton={false}
              customFooter={logoFooter()}
              className="stripe-modal">
      {ready && <StripeElements>
        <WalletInfo cartItems={cartItems} currentUser={currentUser} wallet={wallet} price={price?.price} />
        <StripeForm onSubmit={handleSubmit}
                    onSuccess={handleFormSuccess}
                    onError={handleFormError}
                    operator={currentUser}
                    className="stripe-form"
                    cartItems={cartItems}
                    customer={customer}
                    paymentSchedule={isPaymentSchedule()}>
          {hasErrors() && <div className="stripe-errors">
            {errors}
          </div>}
          {isPaymentSchedule() && <div className="payment-schedule-info">
            <HtmlTranslate trKey="app.shared.stripe.payment_schedule_html" options={{ DEADLINES: schedule.items.length }} />
          </div>}
          {hasCgv() && <div className="terms-of-sales">
            <input type="checkbox" id="acceptToS" name="acceptCondition" checked={tos} onChange={toggleTos} required />
            <label htmlFor="acceptToS">{ t('app.shared.stripe.i_have_read_and_accept_') }
              <a href={cgv.custom_asset_file_attributes.attachment_url} target="_blank">
                { t('app.shared.stripe._the_general_terms_and_conditions') }
              </a>
            </label>
          </div>}
        </StripeForm>
        {!submitState && <button type="submit"
                                 disabled={!canSubmit()}
                                 form="stripe-form"
                                 className="validate-btn">
          {t('app.shared.stripe.confirm_payment_of_', { AMOUNT: formatPrice(remainingPrice) })}
        </button>}
        {submitState && <div className="payment-pending">
          <div className="fa-2x">
            <i className="fas fa-circle-notch fa-spin" />
          </div>
        </div>}
      </StripeElements>}
    </FabModal>
  );
}

const StripeModalWrapper: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, currentUser, schedule , cartItems, customer }) => {
  return (
    <Loader>
      <StripeModal isOpen={isOpen} toggleModal={toggleModal} afterSuccess={afterSuccess} currentUser={currentUser} schedule={schedule} cartItems={cartItems} customer={customer} />
    </Loader>
  );
}

Application.Components.component('stripeModal', react2angular(StripeModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess','currentUser', 'schedule', 'cartItems', 'customer']));
