import React, { FormEvent, FunctionComponent, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import KRGlue from "@lyracom/embedded-form-glue";
import { CartItems } from '../../../models/payment';
import { User } from '../../../models/user';
import SettingAPI from '../../../api/setting';
import { SettingName } from '../../../models/setting';
import PayzenAPI from '../../../api/payzen';
import { Loader } from '../../base/loader';

interface PayzenFormProps {
  onSubmit: () => void,
  onSuccess: (result: any) => void,
  onError: (message: string) => void,
  customer: User,
  operator: User,
  className?: string,
  paymentSchedule?: boolean,
  cartItems?: CartItems,
  formId: string,
}

/**
 * A form component to collect the credit card details and to create the payment method on Stripe.
 * The form validation button must be created elsewhere, using the attribute form={formId}.
 */
export const PayzenForm: React.FC<PayzenFormProps> = ({ onSubmit, onSuccess, onError, children, className, paymentSchedule = false, cartItems, customer, operator, formId }) => {

  const { t } = useTranslation('shared');
  const PayZenKR = useRef(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const api = new SettingAPI();
    api.query([SettingName.PayZenEndpoint, SettingName.PayZenPublicKey]).then(settings => {
      PayzenAPI.chargeCreatePayment(cartItems, customer).then(formToken => {
        KRGlue.loadLibrary(settings.get(SettingName.PayZenEndpoint), settings.get(SettingName.PayZenPublicKey)) /* Load the remote library */
          .then(({ KR }) =>
            KR.setFormConfig({
              formToken: formToken.formToken,
            })
          )
          .then(({ KR }) => KR.addForm("#payzenPaymentForm"))
          .then(({ KR, result }) => KR.showForm(result.formId))
          .then(({ KR }) => KR.onFormReady(handleFormReady))
          .then(({ KR }) => PayZenKR.current = KR);
      }).catch(error => onError(error));
    });
  }, [cartItems, paymentSchedule, customer]);

  /**
   * Callback triggered on PayZen successful payments
   */
  const onPaid = (event) => {
    if (event.clientAnswer.orderStatus === 'PAID') {
      PayZenKR.current.removeForms();
      onSuccess(event.clientAnswer);
    } else {
      onError(event.clientAnswer);
    }
  };

  const handleFormReady = () => {
    setLoading(false);
  };

  /**
   * Callback triggered when the PayZen payment was refused
   */
  const handleError = (answer) => {
    const message = `${answer.errorMessage}. ${answer.detailedErrorMessage ? answer.detailedErrorMessage : ''}`;
    onError(message);
  }

  /**
   * Handle the submission of the form.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    onSubmit();

    try {
      const { result } = await PayZenKR.current.validateForm();
      if (result === null) {
        PayZenKR.current.onSubmit(onPaid);
        PayZenKR.current.onError(handleError);
        await PayZenKR.current.submit();
      }
    } catch (err) {
      // catch api errors
      onError(err);
    }
  }

  const Loader: FunctionComponent = () => {
    return (
      <div className="fa-3x loader">
        <i className="fas fa-circle-notch fa-spin" />
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit} id={formId} className={className ? className : ''}>
      {loading && <Loader />}
      <div className="container">
        <div id="payzenPaymentForm" />
      </div>
      {children}
    </form>
  );
}
