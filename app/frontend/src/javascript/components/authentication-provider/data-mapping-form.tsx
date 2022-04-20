import React, { useEffect, useState } from 'react';
import { UseFormRegister, useFieldArray, ArrayPath, useWatch, Path } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import AuthProviderAPI from '../../api/auth-provider';
import { MappingFields, mappingType, ProvidableType } from '../../models/authentication-provider';
import { Control } from 'react-hook-form/dist/types/form';
import { FormSelect } from '../form/form-select';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { TypeMappingModal } from './type-mapping-modal';
import { useImmer } from 'use-immer';
import { Oauth2DataMappingForm } from './oauth2-data-mapping-form';
import { OpenidConnectDataMappingForm } from './openid-connect-data-mapping-form';

export interface DataMappingFormProps<TFieldValues, TContext extends object> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  providerType: ProvidableType,
}

type selectModelFieldOption = { value: string, label: string };

/**
 * Partial form to define the mapping of the data between the API of the authentication provider and the application internals.
 */
export const DataMappingForm = <TFieldValues extends FieldValues, TContext extends object>({ register, control, providerType }: DataMappingFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');
  const [dataMapping, setDataMapping] = useState<MappingFields>(null);
  const [isOpenTypeMappingModal, updateIsOpenTypeMappingModal] = useImmer<Map<number, boolean>>(new Map());

  const { fields, append, remove } = useFieldArray({ control, name: 'auth_provider_mappings_attributes' as ArrayPath<TFieldValues> });
  const output = useWatch({ name: 'auth_provider_mappings_attributes' as Path<TFieldValues>, control });

  /**
   * Build the list of available models for the data mapping
   */
  const buildModelOptions = (): Array<selectModelFieldOption> => {
    if (!dataMapping) return [];

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
    if (!dataMapping) return [];

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
  const getDataType = (formData: Array<TFieldValues>, index: number): mappingType => {
    const model = getModel(formData, index);
    const field = getField(formData, index);
    if (model && field && dataMapping) {
      return dataMapping[model]?.find(f => f[0] === field)?.[1];
    }
  };

  /**
   * Open/closes the "edit type mapping" modal dialog for the given mapping index
   */
  const toggleTypeMappingModal = (index: number): () => void => {
    return () => {
      updateIsOpenTypeMappingModal(draft => draft.set(index, !draft.get(index)));
    };
  };

  // fetch the mapping data from the API on mount
  useEffect(() => {
    AuthProviderAPI.mappingFields().then((data) => {
      setDataMapping(data);
    });
  }, []);

  return (
    <div className="data-mapping-form array-mapping-form">
      <h4>{t('app.admin.authentication.data_mapping_form.define_the_fields_mapping')}</h4>
      <div className="mapping-actions">
        <FabButton
          icon={<i className="fa fa-plus"/>}
          onClick={() => append({})}>
           {t('app.admin.authentication.data_mapping_form.add_a_match')}
        </FabButton>
      </div>
      {fields.map((item, index) => (
        <div key={item.id} className="mapping-item">
          <div className="inputs">
            <FormInput id={`auth_provider_mappings_attributes.${index}.id`} register={register} type="hidden" />
            <div className="local-data">
              <FormSelect id={`auth_provider_mappings_attributes.${index}.local_model`}
                          control={control} rules={{ required: true }}
                          options={buildModelOptions()}
                          label={t('app.admin.authentication.data_mapping_form.model')}/>
              <FormSelect id={`auth_provider_mappings_attributes.${index}.local_field`}
                          options={buildFieldOptions(output, index)}
                          control={control}
                          rules={{ required: true }}
                          label={t('app.admin.authentication.data_mapping_form.field')} />
            </div>
            <div className="remote-data">
              {providerType === 'OAuth2Provider' && <Oauth2DataMappingForm register={register} control={control} index={index} />}
              {providerType === 'OpenIdConnectProvider' && <OpenidConnectDataMappingForm register={register} index={index} />}
            </div>
          </div>
          <div className="actions">
            <FabButton icon={<i className="fa fa-random" />}
                       onClick={toggleTypeMappingModal(index)}
                       disabled={getField(output, index) === undefined}
                       tooltip={t('app.admin.authentication.data_mapping_form.data_mapping')} />
            <FabButton icon={<i className="fa fa-trash" />} onClick={() => remove(index)} className="delete-button" />
            <TypeMappingModal model={getModel(output, index)}
                              field={getField(output, index)}
                              type={getDataType(output, index)}
                              isOpen={isOpenTypeMappingModal.get(index)}
                              toggleModal={toggleTypeMappingModal(index)}
                              control={control} register={register}
                              fieldMappingId={index} />
          </div>
        </div>
      ))}
    </div>
  );
};
