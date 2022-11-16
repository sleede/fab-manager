import { ArrayPath, useFieldArray, UseFormRegister } from 'react-hook-form';
import { Control } from 'react-hook-form/dist/types/form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { FormInput } from '../form/form-input';

export interface IntegerMappingFormProps<TFieldValues, TContext extends object> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  fieldMappingId: number,
}

/**
 * Partial for to map an internal integer field to an external API providing a string value.
 */
export const IntegerMappingForm = <TFieldValues extends FieldValues, TContext extends object>({ register, control, fieldMappingId }: IntegerMappingFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  const { fields, append, remove } = useFieldArray({ control, name: 'auth_provider_mappings_attributes_transformation_mapping' as ArrayPath<TFieldValues> });

  return (
    <div className="integer-mapping-form array-mapping-form">
      <h4>{t('app.admin.authentication.integer_mapping_form.mappings')}</h4>
      <div className="mapping-actions">
        <FabButton
          icon={<i className="fa fa-plus" />}
          onClick={() => append({})} />
      </div>
      {fields.map((item, index) => (
        <div key={item.id} className="mapping-item">
          <div className="inputs">
            <FormInput id={`auth_provider_mappings_attributes.${fieldMappingId}.transformation.mapping.${index}.from`}
                       register={register}
                       rules={{ required: true }}
                       label={t('app.admin.authentication.integer_mapping_form.mapping_from')} />
            <FormInput id={`auth_provider_mappings_attributes.${fieldMappingId}.transformation.mapping.${index}.to`}
                       register={register}
                       type="number"
                       rules={{ required: true }}
                       label={t('app.admin.authentication.integer_mapping_form.mapping_to')} />
          </div>
          <div className="actions">
            <FabButton icon={<i className="fa fa-trash" />} onClick={() => remove(index)} className="delete-button" />
          </div>
        </div>
      ))}
    </div>
  );
};
