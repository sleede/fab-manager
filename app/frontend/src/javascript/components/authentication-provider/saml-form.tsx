import { FormInput } from '../form/form-input';
import { FormSwitch } from '../form/form-switch';
import { UseFormRegister, FormState, Control } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FabOutputCopy } from '../base/fab-output-copy';

interface SamlFormProps<TFieldValues, TContext extends object> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  formState: FormState<TFieldValues>,
  strategyName?: string,
}

/**
 * Partial form to fill the OAuth2 settings for a new/existing authentication provider.
 */
export const SamlForm = <TFieldValues extends FieldValues, TContext extends object>({ register, strategyName, formState, control }: SamlFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  /**
   * Build the callback URL, based on the strategy name.
   */
  const buildCallbackUrl = (): string => {
    return `${window.location.origin}/users/auth/${strategyName}/callback`;
  };

  return (
    <div className="saml-form">
      <hr/>
      <FabOutputCopy text={buildCallbackUrl()} label={t('app.admin.authentication.saml_form.authorization_callback_url')} />
      <FormInput id="providable_attributes.sp_entity_id"
                 register={register}
                 label={t('app.admin.authentication.saml_form.sp_entity_id')}
                 tooltip={t('app.admin.authentication.saml_form.sp_entity_id_help')}
                 rules={{ required: true }}
                 formState={formState} />
      <FormInput id="providable_attributes.idp_sso_service_url"
                 register={register}
                 placeholder="https://sso.example.net..."
                 label={t('app.admin.authentication.saml_form.idp_sso_service_url')}
                 tooltip={t('app.admin.authentication.saml_form.idp_sso_service_url_help')}
                 rules={{ required: true }}
                 formState={formState} />
      <FormInput id="providable_attributes.idp_cert_fingerprint"
                 register={register}
                 placeholder="E7:91:B2:E1:..."
                 label={t('app.admin.authentication.saml_form.idp_cert_fingerprint')}
                 formState={formState} />
      <FormInput id="providable_attributes.idp_cert"
                 register={register}
                 placeholder="-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----"
                 label={t('app.admin.authentication.saml_form.idp_cert')}
                 formState={formState} />
      <FormInput id="providable_attributes.profile_url"
                 register={register}
                 placeholder="https://exemple.net/user..."
                 label={t('app.admin.authentication.saml_form.profile_edition_url')}
                 tooltip={t('app.admin.authentication.saml_form.profile_edition_url_help')}
                 rules={{ required: true }}
                 formState={formState} />
      <FormInput id="providable_attributes.idp_slo_service_url"
                 register={register}
                 placeholder="https://sso.exemple.net..."
                 label={t('app.admin.authentication.saml_form.idp_slo_service_url')}
                 tooltip={t('app.admin.authentication.saml_form.idp_slo_service_url_help')}
                 formState={formState} />
      <FormInput id="providable_attributes.uid_attribute"
                 register={register}
                 label={t('app.admin.authentication.saml_form.uid_attribute')}
                 tooltip={t('app.admin.authentication.saml_form.uid_attribute_help')}
                 formState={formState} />
      <FormSwitch id="providable_attributes.authn_requests_signed" control={control}
                  formState={formState}
                  label={t('app.admin.authentication.saml_form.authn_requests_signed')} />
      <FormSwitch id="providable_attributes.want_assertions_signed" control={control}
                  formState={formState}
                  label={t('app.admin.authentication.saml_form.want_assertions_signed')} />
      <FormInput id="providable_attributes.sp_certificate"
                 register={register}
                 placeholder="-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----"
                 label={t('app.admin.authentication.saml_form.sp_certificate')}
                 formState={formState} />
      <FormInput id="providable_attributes.sp_private_key"
                 register={register}
                 placeholder="-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----"
                 label={t('app.admin.authentication.saml_form.sp_private_key')}
                 formState={formState} />
    </div>
  );
};
