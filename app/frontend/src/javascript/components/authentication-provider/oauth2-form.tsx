import React from 'react';
import { FormInput } from '../form/form-input';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';

interface Oauth2FormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
}

/**
 * Partial form to fill the OAuth2 settings for a new/existing authentication provider.
 */
export const Oauth2Form = <TFieldValues extends FieldValues>({ register }: Oauth2FormProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  // regular expression to validate the the input fields
  const endpointRegex = /^\/?([-._~:?#[\]@!$&'()*+,;=%\w]+\/?)*$/;
  const urlRegex = /^(https?:\/\/)([\da-z.-]+)\.([-a-z0-9.]{2,30})([/\w .-]*)*\/?$/;

  return (
    <div className="oauth2-form">
      <hr/>
      <FormInput id="base_url"
                 register={register}
                 placeholder="https://sso.example.net..."
                 label={t('app.shared.oauth2.common_url')}
                 rules={{ required: true, pattern: urlRegex }} />
      <FormInput id="authorization_endpoint"
                 register={register}
                 placeholder="/oauth2/auth..."
                 label={t('app.shared.oauth2.authorization_endpoint')}
                 rules={{ required: true, pattern: endpointRegex }} />
      <FormInput id="token_endpoint"
                 register={register}
                 placeholder="/oauth2/token..."
                 label={t('app.shared.oauth2.token_acquisition_endpoint')}
                 rules={{ required: true, pattern: endpointRegex }} />
      <FormInput id="profile_url"
                 register={register}
                 placeholder="https://exemple.net/user..."
                 label={t('app.shared.oauth2.profil_edition_url')}
                 rules={{ required: true, pattern: urlRegex }} />
      <FormInput id="client_id"
                 register={register}
                 label={t('app.shared.oauth2.client_identifier')}
                 rules={{ required: true }} />
      <FormInput id="client_secret"
                 register={register}
                 label={t('app.shared.oauth2.client_secret')}
                 rules={{ required: true }} />
      <FormInput id="scopes" register={register}
                 placeholder="profile,email..."
                 label={t('app.shared.oauth2.scopes')} />
    </div>
  );
};
