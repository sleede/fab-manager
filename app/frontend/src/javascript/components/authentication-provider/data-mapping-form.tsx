import React, { useEffect, useState } from 'react';
import { UseFormRegister, useFieldArray, ArrayPath, useWatch, Path } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import AuthProviderAPI from '../../api/auth-provider';
import { MappingFields } from '../../models/authentication-provider';
import { Control } from 'react-hook-form/dist/types/form';
import { FormSelect } from '../form/form-select';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { TypeMappingModal } from './type-mapping-modal';

export interface DataMappingFormProps<TFieldValues, TContext extends object> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
}

type selectModelFieldOption = { value: string, label: string };

export const DataMappingForm = <TFieldValues extends FieldValues, TContext extends object>({ register, control }: DataMappingFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('shared');
  const [dataMapping, setDataMapping] = useState<MappingFields>(null);
  const [isOpenTypeMappingModal, setIsOpenTypeMappingModal] = useState<boolean>(false);

  const { fields, append, remove } = useFieldArray({ control, name: 'auth_provider_mappings_attributes' as ArrayPath<TFieldValues> });
  const output = useWatch({ name: 'auth_provider_mappings_attributes' as Path<TFieldValues>, control });

  /**
   * Build the list of available models for the data mapping
   */
  const buildModelOptions = (): Array<selectModelFieldOption> => {
    return Object.keys(dataMapping).map(model => {
      return {
        label: model,
        value: model
      };
    }) || [];
  };

  /**
   * Build the list of fields of the current model for the data mapping
   */
  const buildFieldOptions = (formData: Array<TFieldValues>, index: number): Array<selectModelFieldOption> => {
    return dataMapping[getModel(formData, index)]?.map(field => {
      return {
        label: field[0],
        value: field[0]
      };
    }) || [];
  };

  /**
   * Return the name of the modal for the given index, in the current data-mapping form
   */
  const getModel = (formData: Array<TFieldValues>, index: number): string => {
    return formData ? formData[index]?.local_model : undefined;
  };

  /**
   * Return the name of the field for the given index, in the current data-mapping form
   */
  const getField = (formData: Array<TFieldValues>, index: number): string => {
    return formData ? formData[index]?.local_field : undefined;
  };

  /**
   * Return the type of data expected for the given index, in the current data-mapping form
   */
  const getDataType = (formData: Array<TFieldValues>, index: number): string => {
    const model = getModel(formData, index);
    const field = getField(formData, index);
    if (model && field) {
      return dataMapping[model]?.find(f => f[0] === field)?.[1];
    }
  };

  /**
   * Open/closes the "edit type mapping" modal dialog
   */
  const toggleTypeMappingModal = (): void => {
    setIsOpenTypeMappingModal(!isOpenTypeMappingModal);
  };

  // fetch the mapping data from the API on mount
  useEffect(() => {
    AuthProviderAPI.mappingFields().then((data) => {
      setDataMapping(data);
    });
  }, []);

  return (
    <div className="data-mapping-form">
      <h4>{t('app.shared.oauth2.define_the_fields_mapping')}</h4>
      <FabButton
        icon={<i className="fa fa-plus"/>}
        onClick={() => append({})}>
         {t('app.shared.oauth2.add_a_match')}
      </FabButton>
      {fields.map((item, index) => (
        <div key={item.id} className="data-mapping-item">
          <div className="inputs">
            <FormInput id={`auth_provider_mappings_attributes.${index}.id`} register={register} type="hidden" />
            <div className="local-data">
              <FormSelect id={`auth_provider_mappings_attributes.${index}.local_model`} control={control} rules={{ required: true }} options={buildModelOptions()} label={t('app.shared.oauth2.model')}/>
              <FormSelect id={`auth_provider_mappings_attributes.${index}.local_field`} options={buildFieldOptions(output, index)} control={control} rules={{ required: true }} label={t('app.shared.oauth2.field')} />
            </div>
            <div className="remote-data">
              <FormInput id={`auth_provider_mappings_attributes.${index}.api_endpoint`} register={register} rules={{ required: true }} placeholder="/api/resource..." label={t('app.shared.oauth2.api_endpoint_url')} />
              <FormSelect id={`auth_provider_mappings_attributes.${index}.api_data_type`} options={[{ label: 'JSON', value: 'json' }]} control={control} rules={{ required: true }} label={t('app.shared.oauth2.api_type')} />
              <FormInput id={`auth_provider_mappings_attributes.${index}.api_field`} register={register} rules={{ required: true }} placeholder="field_name..." label={t('app.shared.oauth2.api_fields')} />
            </div>
          </div>
          <div className="actions">
            <FabButton icon={<i className="fa fa-random" />} onClick={toggleTypeMappingModal} />
            <FabButton icon={<i className="fa fa-trash" />} onClick={() => remove(index)} className="delete-button" />
            <TypeMappingModal model={getModel(output, index)} field={getField(output, index)} type={getDataType(output, index)} isOpen={isOpenTypeMappingModal} toggleModal={toggleTypeMappingModal} />
          </div>
        </div>
      ))}
    </div>
  );
};
