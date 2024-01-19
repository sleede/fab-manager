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
                 placeholder="https://sso.example.net..."
                 label={t('app.admin.authentication.saml_form.sp_entity_id')}
                 rules={{ required: true }}
                 formState={formState} />
      <FormInput id="providable_attributes.idp_sso_service_url"
                 register={register}
                 placeholder="/saml/auth..."
                 label={t('app.admin.authentication.saml_form.idp_sso_service_url')}
                 rules={{ required: true, pattern: ValidationLib.urlRegex }}
                 formState={formState} />
    </div>
  );
};
