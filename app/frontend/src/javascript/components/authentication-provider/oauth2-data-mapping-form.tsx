import React from 'react';
import { UseFormRegister } from 'react-hook-form';
import { Control } from 'react-hook-form/dist/types/form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';
import { FormSelect } from '../form/form-select';
import { HtmlTranslate } from '../base/html-translate';
import { useTranslation } from 'react-i18next';

interface Oauth2DataMappingFormProps<TFieldValues, TContext extends object> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  index: number,
}

export const Oauth2DataMappingForm = <TFieldValues extends FieldValues, TContext extends object>({ register, control, index }: Oauth2DataMappingFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  return (
    <div className="oauth2-data-mapping-form">
      <FormInput id={`auth_provider_mappings_attributes.${index}.api_endpoint`}
                 register={register}
                 rules={{ required: true }}
                 placeholder="/api/resource..."
                 label={t('app.admin.authentication.oauth2_data_mapping_form.api_endpoint_url')} />
      <FormSelect id={`auth_provider_mappings_attributes.${index}.api_data_type`}
                  options={[{ label: 'JSON', value: 'json' }]}
                  control={control} rules={{ required: true }}
                  label={t('app.admin.authentication.oauth2_data_mapping_form.api_type')} />
      <FormInput id={`auth_provider_mappings_attributes.${index}.api_field`}
                 register={register}
                 rules={{ required: true }}
                 placeholder="field_name..."
                 tooltip={<HtmlTranslate trKey="app.admin.authentication.oauth2_data_mapping_form.api_field_help_html" />}
                 label={t('app.admin.authentication.oauth2_data_mapping_form.api_field')} />
    </div>
  );
};
