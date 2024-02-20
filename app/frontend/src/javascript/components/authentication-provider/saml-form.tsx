import { FormInput } from '../form/form-input';
import { UseFormRegister, FormState } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FabOutputCopy } from '../base/fab-output-copy';
import ValidationLib from '../../lib/validation';

interface SamlFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  formState: FormState<TFieldValues>,
  strategyName?: string,
}

/**
 * Partial form to fill the OAuth2 settings for a new/existing authentication provider.
 */
export const SamlForm = <TFieldValues extends FieldValues>({ register, strategyName, formState }: SamlFormProps<TFieldValues>) => {
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
                 rules={{ required: true, pattern: ValidationLib.urlRegex }}
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
                 rules={{ required: true, pattern: ValidationLib.urlRegex }}
                 formState={formState} />
      <FormInput id="providable_attributes.idp_slo_service_url"
                 register={register}
                 placeholder="https://sso.exemple.net..."
                 label={t('app.admin.authentication.saml_form.idp_slo_service_url')}
                 tooltip={t('app.admin.authentication.saml_form.idp_slo_service_url_help')}
                 rules={{ pattern: ValidationLib.urlRegex }}
                 formState={formState} />
    </div>
  );
};
