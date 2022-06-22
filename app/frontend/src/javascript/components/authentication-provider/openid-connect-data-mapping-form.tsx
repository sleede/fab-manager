import React from 'react';
import { Path, UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';
import { HtmlTranslate } from '../base/html-translate';
import { useTranslation } from 'react-i18next';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FabButton } from '../base/fab-button';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { AuthenticationProviderMapping } from '../../models/authentication-provider';

interface OpenidConnectDataMappingFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  setValue: UseFormSetValue<TFieldValues>,
  currentFormValues: Array<AuthenticationProviderMapping>,
  index: number,
}

/**
 * Partial form to set the data mapping for an OpenID Connect provider.
 * The data mapping is the way to bind data from the OIDC claims to the Fab-manager's database
 */
export const OpenidConnectDataMappingForm = <TFieldValues extends FieldValues>({ register, setValue, currentFormValues, index }: OpenidConnectDataMappingFormProps<TFieldValues>) => {
  const { t } = useTranslation('admin');

  const standardConfiguration = {
    'user.uid': { api_field: 'sub' },
    'user.email': { api_field: 'email' },
    'user.username': { api_field: 'preferred_username' },
    'profile.first_name': { api_field: 'given_name' },
    'profile.last_name': { api_field: 'family_name' },
    'profile.avatar': { api_field: 'picture' },
    'profile.website': { api_field: 'website' },
    'profile.gender': { api_field: 'gender', transformation: { true_value: 'male', false_value: 'female' } },
    'profile.birthday': { api_field: 'birthdate', transformation: { format: 'iso8601' } },
    'profile.phone': { api_field: 'phone_number' },
    'profile.address': { api_field: 'address.formatted' }
  };

  /**
   * Set the data mapping according to the standard OpenID Connect specification
   */
  const openIdStandardConfiguration = (): void => {
    const model = currentFormValues[index]?.local_model;
    const field = currentFormValues[index]?.local_field;
    const configuration = standardConfiguration[`${model}.${field}`];
    if (configuration) {
      setValue(
        `auth_provider_mappings_attributes.${index}.api_field` as Path<TFieldValues>,
        configuration.api_field as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
      );
      if (configuration.transformation) {
        Object.keys(configuration.transformation).forEach((key) => {
          setValue(
            `auth_provider_mappings_attributes.${index}.transformation.${key}` as Path<TFieldValues>,
            configuration.transformation[key] as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
          );
        });
      }
    }
  };

  return (
    <div className="openid-connect-data-mapping-form">
      <FormInput id={`auth_provider_mappings_attributes.${index}.api_endpoint`}
                 type="hidden"
                 register={register}
                 rules={{ required: true }}
                 defaultValue="user_info" />
      <FormInput id={`auth_provider_mappings_attributes.${index}.api_data_type`}
                 type="hidden"
                 register={register}
                 rules={{ required: true }}
                 defaultValue="json" />
      <FormInput id={`auth_provider_mappings_attributes.${index}.api_field`}
                 register={register}
                 rules={{ required: true }}
                 placeholder="claim..."
                 tooltip={<HtmlTranslate trKey="app.admin.authentication.openid_connect_data_mapping_form.api_field_help_html" />}
                 label={t('app.admin.authentication.openid_connect_data_mapping_form.api_field')} />
      <FabButton
        icon={<i className="fa fa-magic" />}
        className="auto-configure-button"
        onClick={openIdStandardConfiguration}
        tooltip={t('app.admin.authentication.openid_connect_data_mapping_form.openid_standard_configuration')} />
    </div>
  );
};
