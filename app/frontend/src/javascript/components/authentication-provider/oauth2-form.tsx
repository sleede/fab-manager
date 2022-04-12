import React from 'react';
import { FormInput } from '../form/form-input';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FabOutputCopy } from '../base/fab-output-copy';

interface Oauth2FormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  callbackUrl?: string,
}

/**
 * Partial form to fill the OAuth2 settings for a new/existing authentication provider.
 */
export const Oauth2Form = <TFieldValues extends FieldValues>({ register, callbackUrl }: Oauth2FormProps<TFieldValues>) => {
  const { t } = useTranslation('admin');

  // regular expression to validate the the input fields
  const endpointRegex = /^\/?([-._~:?#[\]@!$&'()*+,;=%\w]+\/?)*$/;
  const urlRegex = /^(https?:\/\/)([\da-z.-]+)\.([-a-z0-9.]{2,30})([/\w .-]*)*\/?$/;

  return (
    <div className="oauth2-form">
      <hr/>
      <FabOutputCopy text={callbackUrl} label={t('app.admin.authentication.oauth2_form.authorization_callback_url')} />
      <FormInput id="providable_attributes.base_url"
                 register={register}
                 placeholder="https://sso.example.net..."
                 label={t('app.admin.authentication.oauth2_form.common_url')}
                 rules={{ required: true, pattern: urlRegex }} />
      <FormInput id="providable_attributes.authorization_endpoint"
                 register={register}
                 placeholder="/oauth2/auth..."
                 label={t('app.admin.authentication.oauth2_form.authorization_endpoint')}
                 rules={{ required: true, pattern: endpointRegex }} />
      <FormInput id="providable_attributes.token_endpoint"
                 register={register}
                 placeholder="/oauth2/token..."
                 label={t('app.admin.authentication.oauth2_form.token_acquisition_endpoint')}
                 rules={{ required: true, pattern: endpointRegex }} />
      <FormInput id="providable_attributes.profile_url"
                 register={register}
                 placeholder="https://exemple.net/user..."
                 label={t('app.admin.authentication.oauth2_form.profil_edition_url')}
                 rules={{ required: true, pattern: urlRegex }} />
      <FormInput id="providable_attributes.client_id"
                 register={register}
                 label={t('app.admin.authentication.oauth2_form.client_identifier')}
                 rules={{ required: true }} />
      <FormInput id="providable_attributes.client_secret"
                 register={register}
                 label={t('app.admin.authentication.oauth2_form.client_secret')}
                 rules={{ required: true }} />
      <FormInput id="providable_attributes.scopes" register={register}
                 placeholder="profile,email..."
                 label={t('app.admin.authentication.oauth2_form.scopes')} />
    </div>
  );
};
