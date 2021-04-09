import React, { FormEvent, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import KRGlue from "@lyracom/embedded-form-glue";
import { CartItems } from '../../../models/payment';
import { User } from '../../../models/user';
import SettingAPI from '../../../api/setting';
import { SettingName } from '../../../models/setting';

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

  useEffect(() => {
    const api = new SettingAPI();
    api.query([SettingName.PayZenEndpoint, SettingName.PayZenPublicKey]).then(settings => {
      const formToken = "DEMO-TOKEN-TO-BE-REPLACED";

      KRGlue.loadLibrary(settings.get(SettingName.PayZenEndpoint), settings.get(SettingName.PayZenPublicKey)) /* Load the remote library */
        .then(({ KR }) =>
          KR.setFormConfig({
            /* set the minimal configuration */
            formToken: formToken,
            "kr-language": "en-US" /* to update initialization parameter */
          })
        )
        .then(({ KR }) =>
          KR.addForm("#payzenPaymentForm")
        ) /* add a payment form  to myPaymentForm div*/
        .then(({ KR, result }) =>
          KR.showForm(result.formId)
        ); /* show the payment form */
    }).catch(error => console.error(error));
  });

  /**
   * Handle the submission of the form.
   */
  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    onSubmit();


    try {
      onSuccess(null);
    } catch (err) {
      // catch api errors
      onError(err);
    }

  }


  return (
    <form onSubmit={handleSubmit} id={formId} className={className ? className : ''}>
      <div className="container">
        <div id="payzenPaymentForm" />
      </div>
      {children}
    </form>
  );
}
