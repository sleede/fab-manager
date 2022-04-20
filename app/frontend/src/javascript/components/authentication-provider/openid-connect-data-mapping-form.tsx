import React from 'react';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';
import { HtmlTranslate } from '../base/html-translate';
import { useTranslation } from 'react-i18next';

interface OpenidConnectDataMappingFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  index: number,
}

export const OpenidConnectDataMappingForm = <TFieldValues extends FieldValues>({ register, index }: OpenidConnectDataMappingFormProps<TFieldValues>) => {
  const { t } = useTranslation('admin');

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
    </div>
  );
};
