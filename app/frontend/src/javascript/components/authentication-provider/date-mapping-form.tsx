import React from 'react';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FormSelect } from '../form/form-select';
import { Control } from 'react-hook-form/dist/types/form';

export interface DateMappingFormProps<TFieldValues, TContext extends object> {
  control: Control<TFieldValues, TContext>,
  fieldMappingId: number,
}

/**
 * Partial form for mapping an internal date field to an external API.
 */
export const DateMappingForm = <TFieldValues extends FieldValues, TContext extends object>({ control, fieldMappingId }: DateMappingFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  // available date formats
  const dateFormats = [
    {
      label: 'ISO 8601',
      value: 'iso8601'
    },
    {
      label: 'RFC 2822',
      value: 'rfc2822'
    },
    {
      label: 'RFC 3339',
      value: 'rfc3339'
    },
    {
      label: 'Timestamp (s)',
      value: 'timestamp-s'
    },
    {
      label: 'Timestamp (ms)',
      value: 'timestamp-ms'
    }
  ];

  return (
    <div className="date-mapping-form">
      <h4>{t('app.admin.authentication.date_mapping_form.input_format')}</h4>
      <FormSelect id={`auth_provider_mappings_attributes.${fieldMappingId}.transformation.format`}
                  control={control}
                  rules={{ required: true }}
                  options={dateFormats}
                  label={t('app.admin.authentication.date_mapping_form.date_format')} />
    </div>
  );
};
