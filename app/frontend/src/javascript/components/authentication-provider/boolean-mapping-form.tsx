import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';

export interface BooleanMappingFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  fieldMappingId: number,
}

/**
 * Partial form to map an internal boolean field to an external API providing a string value.
 */
export const BooleanMappingForm = <TFieldValues extends FieldValues>({ register, fieldMappingId }: BooleanMappingFormProps<TFieldValues>) => {
  const { t } = useTranslation('admin');

  return (
    <div className="boolean-mapping-form">
      <h4>{t('app.admin.authentication.boolean_mapping_form.mappings')}</h4>
      <FormInput id={`auth_provider_mappings_attributes.${fieldMappingId}.transformation.true_value`}
                 register={register}
                 rules={{ required: true }}
                 label={t('app.admin.authentication.boolean_mapping_form.true_value')} />
      <FormInput id={`auth_provider_mappings_attributes.${fieldMappingId}.transformation.false_value`}
                 register={register}
                 rules={{ required: true }}
                 label={t('app.admin.authentication.boolean_mapping_form.false_value')} />
    </div>
  );
};
